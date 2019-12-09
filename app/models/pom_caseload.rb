# frozen_string_literal: true

class PomCaseload
  attr_reader :allocations

  def initialize(pom_staff_id, prison)
    @staff_id = pom_staff_id
    @prison = prison
    @allocations = load_allocations
  end

private

  def load_allocations
    offender_hash = @prison.offenders.map { |o| [o.offender_no, o] }.to_h
    allocations = Allocation.
      where(nomis_offender_id: offender_hash.keys).
      active_pom_allocations(@staff_id, @prison.code)
    allocations.map { |alloc|
      AllocatedOffender.new(@staff_id, alloc, offender_hash.fetch(alloc.nomis_offender_id))
    }
  end
end
