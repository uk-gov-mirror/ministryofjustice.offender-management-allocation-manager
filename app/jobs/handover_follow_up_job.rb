class HandoverFollowUpJob < ApplicationJob
  queue_as :default

  def perform(date)
    ldus = LocalDivisionalUnit.all.where.not(email_address: nil)

    ldus.each do |ldu|
      offenders = ldu.teams.map { |team| team.case_information.map(&:nomis_offender_id) }.flatten
                  .select { |offender_id| Allocation.find_by(nomis_offender_id: offender_id, com_name: nil) }
                  .map { |off_id| OffenderService.get_offender(off_id) }
                  .select { |o| o.handover_start_date.present? && o.handover_start_date == date }

      offenders.each do |offender|
        allocation = Allocation.where(prison: offender.prison_id).first
        pom = PrisonOffenderManagerService.get_pom_at(offender.prison_id, allocation.primary_pom_nomis_id)

        CommunityMailer.handover_chase_email(
          nomis_offender_id: offender.offender_no,
          offender_name: offender.full_name,
          offender_crn: offender.crn,
          ldu_email: offender.ldu.email_address,
          prison: PrisonService.name_for(offender.prison_id),
          start_date: offender.handover_start_date,
          responsibility_handover_date: offender.responsibility_handover_date,
          pom_name: pom.full_name,
          pom_email: pom.email_address
        ).deliver_later
      end
    end
  end
end
