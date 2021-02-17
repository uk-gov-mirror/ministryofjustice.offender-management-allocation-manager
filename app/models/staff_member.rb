# frozen_string_literal: true

# This object represents a staff member who may or my not be a POM. It is up to the caller to check
# and do something interesting if they are not a POM at a specific prison.
class StaffMember
  # maybe this method shouldn't be here?
  attr_reader :staff_id

  def initialize(prison, staff_id, pom_detail = default_pom_detail(staff_id))
    @prison = prison
    @staff_id = staff_id.to_i
    @pom_detail = pom_detail
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

  def first_name
    staff_detail.first_name&.titleize
  end

  def last_name
    staff_detail.last_name&.titleize
  end

  def email_address
    HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@staff_id).first
  end

  def has_pom_role?
    poms_list = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(@prison.code)

    poms_list.detect { |pom| pom.staff_id == @staff_id }.present?
  end

  def position
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(@prison.code)
    this_pom = poms.detect { |pom| pom.staff_id == @staff_id }
    if this_pom.nil?
      'STAFF'
    elsif this_pom.prison_officer?
      RecommendationService::PRISON_POM
    else
      RecommendationService::PROBATION_POM
    end
  end

  def working_pattern
    @pom_detail.working_pattern
  end

  def status
    @pom_detail.status
  end

  def allocations
    @allocations ||= fetch_allocations
  end

  def pending_handover_offenders
    allocations.map(&:offender).select(&:approaching_handover?)
  end

private

  def fetch_allocations
    offender_hash = @prison.offenders.index_by(&:offender_no)
    allocations = Allocation.
        where(nomis_offender_id: offender_hash.keys).
        active_pom_allocations(@staff_id, @prison.code)
    allocations.map { |alloc|
      AllocatedOffender.new(@staff_id, alloc, offender_hash.fetch(alloc.nomis_offender_id))
    }
  end

  def default_pom_detail(staff_id)
    @pom_detail = PomDetail.find_or_create_by!(nomis_staff_id: staff_id) { |pom|
      pom.working_pattern = 0.0
      pom.status = 'active'
    }
  end

  def staff_detail
    @staff_detail ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(@staff_id)
  end
end
