require 'rails_helper'

context 'when NOMIS is missing information' do
  let(:prison_code) { 'LEI' }
  let(:offender_no) { 'A1' }
  let(:stub_api_host) { 'http://nomis.mock/elite2api/api' }

  describe 'when logged in' do
    before do
      user_name = 'example_user'
      staff_id = 1

      stub_auth_host = 'http://nomis.mock'
      stub_poms = [{ staffId: 1, position: RecommendationService::PRISON_POM }]

      Rails.configuration.nomis_oauth_host = stub_auth_host

      stub_request(:post, "#{stub_auth_host}/auth/oauth/token").
        with(query: { grant_type: 'client_credentials' }).
        to_return(status: 200, body: {}.to_json)

      stub_request(:get, "#{stub_api_host}/users/example_user").
        to_return(status: 200, body: { staffId: staff_id }.to_json)

      stub_request(:get, "#{stub_api_host}/staff/#{staff_id}/emails").
        to_return(status: 200, body: [].to_json)

      stub_request(:get, "#{stub_api_host}/staff/roles/#{prison_code}/role/POM").
        to_return(status: 200, body: stub_poms.to_json)

      signin_pom_user(user_name)
    end

    describe 'the caseload page' do
      before do
        stub_offenders = [{
          offenderNo: offender_no,
          bookingId: 1,
          dateOfBirth: '1990-01-01',
          imprisonmentStatus: 'LIFE'
        }]

        stub_bookings = [{
          bookingId: 1,
          sentenceDetail: {
            releaseDate: 30.years.from_now.iso8601,
            sentenceStartDate: Time.zone.now.iso8601
          }
        }]

        stub_request(:get, "#{stub_api_host}/locations/description/#{prison_code}/inmates").
          with(query: { convictedStatus: 'Convicted', returnCategory: true }).
          to_return(status: 200, body: stub_offenders.to_json)

        stub_request(:post, "#{stub_api_host}/offender-sentences/bookings").
          to_return(status: 200, body: stub_bookings.to_json)
      end

      it 'does not error' do
        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: 1)

        visit prison_caseload_index_path(prison_code)

        expect(page).to have_content('Showing 1 - 1 of 1 results')
      end
    end

    describe 'the prisoner page' do
      let(:booking_id) { 1 }

      before do
        stub_bookings = [{
          bookingId: booking_id,
          sentenceDetail: {
            releaseDate: 30.years.from_now.iso8601,
            sentenceStartDate: Time.zone.now.iso8601
          }
        }]

        stub_offender = [{
          offenderNo: offender_no,
          latestBookingId: booking_id
        }]

        stub_request(:get, "#{stub_api_host}/prisoners/#{offender_no}").
          to_return(status: 200, body: stub_offender.to_json)

        stub_request(:post, "#{stub_api_host}/offender-assessments/CATEGORY").
          to_return(status: 200, body: {}.to_json)

        stub_request(:get, "#{stub_api_host}/bookings/#{booking_id}/mainOffence").
          to_return(status: 200, body: {}.to_json)

        stub_request(:post, "#{stub_api_host}/offender-sentences/bookings").
          to_return(status: 200, body: stub_bookings.to_json)

        stub_keyworker_host = 'http://keyworker.mock'

        Rails.configuration.keyworker_api_host = stub_keyworker_host

        stub_request(:get, "#{stub_keyworker_host}/key-worker/#{prison_code}/offender/#{offender_no}").
          to_return(status: 200, body: {}.to_json)
      end

      it 'does not error' do
        visit prison_prisoner_path(prison_code, offender_no)

        expect(page).to have_content('Prisoner information')
      end
    end
  end
end
