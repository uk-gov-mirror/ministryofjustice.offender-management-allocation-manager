# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class OffenderApi
      extend PrisonApiClient

      def self.list(prison, page = 0, page_size: 20)
        route = "/locations/description/#{prison}/inmates"

        queryparams = { 'convictedStatus' => 'Convicted', 'returnCategory' => true }

        page_offset = page * page_size
        hdrs = paging_headers(page_size, page_offset)

        total_pages = nil
        data = client.get(
          route, queryparams: queryparams, extra_headers: hdrs
        ) { |_json, response|
          # Get the 'Total-Records' response header to calculate how many pages there are
          total_records = response.headers['Total-Records'].to_i
          total_pages = (total_records / page_size.to_f).ceil
        }

        offender_nos = data.map { |o| o.fetch('offenderNo') }
        search_data = get_search_payload(offender_nos)
        temp_movements = HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for(offender_nos)

        booking_ids = data.map { |o| o.fetch('bookingId') }
        sentence_details = HmppsApi::PrisonApi::OffenderApi.get_bulk_sentence_details(booking_ids)

        complexities = if PrisonService::womens_prison?(prison)
                         HmppsApi::ComplexityApi.get_complexities offender_nos
                       else
                         {}
                       end
        offenders = data.map do |payload|
          offender_no = payload.fetch('offenderNo')
          search_payload = search_data.fetch(offender_no, {})
          HmppsApi::OffenderSummary.new(payload,
                                        search_payload,
                                        latest_temp_movement: temp_movements[offender_no],
                                        complexity_level: complexities[offender_no]).tap { |offender|
            sentencing = sentence_details[offender.booking_id]
            if sentencing.present?
              offender.sentence = HmppsApi::SentenceDetail.new sentencing,
                                                               search_payload
            end
          }
        end
        ApiPaginatedResponse.new(total_pages, offenders)
      end

      def self.get_offender(raw_offender_no)
        # Bad NOMIS numbers mustn't produce invalid URLs
        offender_no = URI.encode_www_form_component(raw_offender_no)
        route = "/prisoners/#{offender_no}"
        api_response = client.get(route).first

        if api_response.nil?
          nil
        else
          search_payload = get_search_payload([offender_no]).fetch(offender_no, {})
          temp_movements = HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for([offender_no])
          complexity_level = if api_response.fetch('currentlyInPrison') == 'Y' && PrisonService::womens_prison?(api_response.fetch('latestLocationId'))
                               HmppsApi::ComplexityApi.get_complexity(offender_no)
                             end
          prisoner = HmppsApi::Offender.new api_response,
                                            search_payload,
                                            latest_temp_movement: temp_movements[offender_no],
                                            complexity_level: complexity_level
          prisoner.tap do |offender|
            sentence_details = get_bulk_sentence_details([offender.booking_id])
            sentence = HmppsApi::SentenceDetail.new sentence_details.fetch(offender.booking_id),
                                                    search_payload

            offender.sentence = sentence
            add_arrival_dates([offender])
          end
        end
      end

      def self.get_offence(booking_id)
        route = "/bookings/#{booking_id}/mainOffence"
        data = client.get(route)
        return '' if data.empty?

        data.first['offenceDescription']
      end

      def self.get_category_code(offender_no)
        route = '/offender-assessments/CATEGORY'
        data = client.post(route, [offender_no], cache: true)
        return '' if data.empty?

        data.first['classificationCode']
      end

      def self.get_category_labels
        route = '/reference-domains/domains/SUP_LVL_TYPE'
        data = client.get(route, extra_headers: { 'Page-Limit': '1000' })
        data.map { |c| [c.fetch('code'), c.fetch('description')] }.to_h
      end

      def self.get_bulk_sentence_details(booking_ids)
        return {} if booking_ids.empty?

        route = '/offender-sentences/bookings'
        data = client.post(route, booking_ids, cache: true)

        data.each_with_object({}) { |record, hash|
          next unless record.key?('bookingId')

          oid = record['bookingId']

          hash[oid] = record.fetch('sentenceDetail')
          hash
        }
      end

      def self.get_image(booking_id)
        # This method returns the raw bytes of an image, the equivalent of loading the
        # image from file on disk.
        details_route = '/offender-sentences/bookings'
        details = client.post(details_route, [booking_id], cache: true)

        return default_image if details.first['facialImageId'].blank?

        image_route = "/images/#{details.first['facialImageId']}/data"
        image = client.raw_get(image_route)

        image.presence || default_image
      rescue Faraday::ResourceNotFound
        # It's possible that the offender does not yet have an image of their
        # face, and so when an image can't be found, we will return the default
        # image instead.
        default_image
      end

      def self.add_arrival_dates(offenders)
        movements = HmppsApi::PrisonApi::MovementApi.admissions_for(offenders.map(&:offender_no))

        offenders.each do |offender|
          arrival = movements.fetch(offender.offender_no, []).reverse.detect { |movement|
            movement.to_agency == offender.prison_id
          }
          offender.prison_arrival_date = [offender.sentence_start_date, arrival&.movement_date].compact.max
        end
      end

    private

      def self.get_search_payload(offender_nos)
        search_route = '/prisoner-numbers'
        search_client.post(search_route, { prisonerNumbers: offender_nos }, cache: true)
                                     .index_by { |prisoner| prisoner.fetch('prisonerNumber') }
      end

      def self.paging_headers(page_size, page_offset)
        {
          'Page-Limit' => page_size.to_s,
          'Page-Offset' => page_offset.to_s
        }
      end

      def self.default_image
        File.read(Rails.root.join('app/assets/images/default_profile_image.jpg'))
      end
    end
  end
end
