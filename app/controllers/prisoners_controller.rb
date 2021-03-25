# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  def show
    @prisoner = OffenderService.get_offender(params[:id])
    @tasks = PomTasks.new.for_offender(@prisoner)
    @allocation = Allocation.find_by(nomis_offender_id: @prisoner.offender_no)

    if @allocation.present?
      @primary_pom_name = helpers.fetch_pom_name(@allocation.primary_pom_nomis_id).
          titleize
    end

    if @allocation.present? && @allocation.secondary_pom_name.present?
      # POM-778 Just not covered by tests
      #:nocov:
      @secondary_pom_name = helpers.fetch_pom_name(@allocation.secondary_pom_nomis_id).titleize
      #:nocov:
    end

    @keyworker = HmppsApi::KeyworkerApi.get_keyworker(
      active_prison_id, @prisoner.offender_no
    )

    @case_info = CaseInformation.includes(:early_allocations).find_by(nomis_offender_id: params[:id])
    @emails_sent_to_ldu = EmailHistory.sent_within_current_sentence(@prisoner, EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
  end

  def image
    @prisoner = OffenderService.get_offender(params[:prisoner_id])
    image_data = HmppsApi::PrisonApi::OffenderApi.get_image(@prisoner.booking_id)

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data image_data, type: 'image/jpg', disposition: 'inline'
  end
end
