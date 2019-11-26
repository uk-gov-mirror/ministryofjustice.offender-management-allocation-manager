# frozen_string_literal: true

class SummaryService
  PAGE_SIZE = 20 # The number of items to show in the view

  # The maximum number of days for an offender to be considered newly arrived
  NEWLY_ARRIVED_DAYS = 2

  # rubocop:disable Metrics/MethodLength
  def self.summary(summary_type, prison)
    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # :pending, or :new_arrivals.  The other types will return totals, and do not contain
    # any data.
    sortable_fields = (summary_type == :allocated ? sort_fields_for_allocated : default_sortable_fields)

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    buckets = { allocated: Bucket.new(sortable_fields),
                unallocated: Bucket.new(sortable_fields),
                pending: Bucket.new(sortable_fields),
                new_arrivals: Bucket.new(sortable_fields)
    }

    offenders = prison.offenders
    active_allocations_hash = AllocationService.active_allocations(offenders.map(&:offender_no), prison.code)

    # We need arrival dates for all offenders and all summary types because it is used to
    # detect new arrivals and so we would not be able to count them without knowing their
    # prison_arrival_date
    add_arrival_dates(offenders) if offenders.any?

    offenders.each do |offender|
      if offender.tier.present?
        # When trying to determine if this offender has a current active allocation, we want to know
        # if it is for this prison.
        if active_allocations_hash.key?(offender.offender_no)
          buckets[:allocated].items << offender
        else
          buckets[:unallocated].items << offender
        end
      elsif offender.awaiting_allocation_for >= NEWLY_ARRIVED_DAYS
        # If the offender has been waiting more than 2 days for their
        # data to be updated, then they will appear in the pending bucket,
        # otherwise the newly_arrived bucket
        bucket[:pending].items << offender
      else
        bucket[:new_arrivals].items << offender
      end
    end

    add_arrival_dates(buckets[:unallocated].items) if buckets[:unallocated].items.any?
    add_arrival_dates(buckets[:pending].items) if buckets[:pending].items.any?

    # For the allocated offenders, we need to provide the allocated POM's
    # name
    buckets[:allocated].items.each do |offender|
      alloc = active_allocations_hash[offender.offender_no]
      offender.allocated_pom_name = restructure_pom_name(alloc.primary_pom_name)
      offender.allocation_date = (alloc.primary_pom_allocated_at || alloc.updated_at)&.to_date
    end

    Summary.new(summary_type).tap { |summary|
      summary.allocated = buckets[:allocated]
      summary.unallocated = buckets[:unallocated]
      summary.pending = buckets[:pending]
      summary.new_arrivals = buckets[:new_arrivals]
    }
  end

# rubocop:enable Metrics/MethodLength

private

  def self.sort_fields_for_allocated
    [:last_name, :earliest_release_date, :tier]
  end

  def self.default_sortable_fields
    [:last_name, :earliest_release_date, :awaiting_allocation_for, :tier]
  end

  def self.add_arrival_dates(offenders)
    movements = Nomis::Elite2::MovementApi.admissions_for(offenders.map(&:offender_no))

    offenders.each do |offender|
      arrival = movements.fetch(offender.offender_no, []).reverse.detect { |movement|
        movement.to_agency == offender.prison_id
      }
      offender.prison_arrival_date = [offender.sentence_start_date, arrival&.create_date_time].compact.max
    end
  end

  def self.restructure_pom_name(pom_name)
    name = pom_name.titleize
    return name if name.include? ','

    parts = name.split(' ')
    "#{parts[1]}, #{parts[0]}"
  end
end
