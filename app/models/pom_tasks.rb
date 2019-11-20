# frozen_string_literal: true

class PomTasks
  # Just for auto_delius_import_enabled
  include ApplicationHelper

  def for_offenders(offenders)
    # For each AllocatedOffender we want to find out if the offender
    # requires any changes to it. This may return multiple tasks for the
    # same offender.
    early_allocs = get_early_allocations(offenders.map(&:offender_no))

    offenders.map { |offender|
      for_offender(offender, early_allocations: early_allocs)
    }.flatten
  end

  def for_offender(offender, early_allocations: nil)
    if early_allocations.nil?
      early_allocations = get_early_allocations([offender.offender_no])
    end

    tasks = []
    unless offender.indeterminate_sentence?
      prd_task = parole_review_date_task(offender)
      tasks << prd_task if prd_task.present?
    end

    delius_task = missing_info_task(offender)
    tasks << delius_task if delius_task.present?

    if early_allocations.key?(offender.offender_no)
      tasks << early_allocation_update_task(offender)
    end

    tasks.compact
  end

  def parole_review_date_task(offender)
    # Offender is indeterminate and their parole review date is old or missing
    ped_in_the_future = offender.parole_eligibility_date.present? && offender.parole_eligibility_date > Time.zone.today
    ted_in_the_future = offender.tariff_date.present? && offender.tariff_date > Time.zone.today

    return if ped_in_the_future || ted_in_the_future

    if offender.parole_review_date.blank? || offender.parole_review_date < Time.zone.today
      PomTaskPresenter.new(
        offender_name: offender.full_name,
        offender_number: offender.offender_no,
        action_label: 'Parole review date',
        long_label: 'Parole review date must be updated so handover dates can be calculated.')
    end
  end

  def missing_info_task(offender)
    return unless auto_delius_import_enabled?(offender.prison_id)

    # Offender had their delius data manually added and as a result are missing
    # new key fields.
    if offender.mappa_level.blank? || offender.ldu.blank?
      PomTaskPresenter.new(
        offender_name: offender.full_name,
        offender_number: offender.offender_no,
        action_label: 'nDelius case matching',
        long_label: 'This prisoner must be linked to an nDelius record so '\
          'community probation details are available. '\
          'See <a href="/update_case_information">how to update case information</a>'
      )
    end
  end

  def early_allocation_update_task(offender)
    # An early allocation request has been made but is pending a response from
    # the community, and therefore needs updating.
    PomTaskPresenter.new(
      offender_name: offender.full_name,
      offender_number: offender.offender_no,
      action_label: 'Early allocation decision',
      long_label: 'The community probation team’s decision about early allocation must be recorded.'
    )
  end

  def get_early_allocations(offender_nos)
    # For the provided offender numbers, determines whether they have an outstanding
    # early allocation and then adds them to a hash for quick lookup.  If a specific
    # offender does have an outstanding early allocation their offender number will
    # appear as a key (with a boolean value). We do this because hash lookup is
    # significantly faster than array/list lookup.
    EarlyAllocation.where(nomis_offender_id: offender_nos).map { |early_allocation|
      if early_allocation.discretionary? && early_allocation.community_decision.nil?
        [early_allocation.nomis_offender_id, true]
      end
    }.compact.to_h
  end
end
