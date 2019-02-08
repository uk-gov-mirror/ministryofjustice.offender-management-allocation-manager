class AllocationService
  def self.create_allocation(params)
    Allocation.transaction do
      Allocation.where(nomis_offender_id: params[:nomis_offender_id]).
        update_all(active: false)

      params[:pom_detail_id] = PrisonOffenderManagerService.
        get_pom_detail(params[:nomis_staff_id]).id

      Allocation.create!(params) do |alloc|
        alloc.active = true
        alloc.save!
      end
    end
  end

  def self.get_override_instance
    AllocationOverride.new
  end

  def self.active_allocations(nomis_offender_ids)
    Allocation.where(nomis_offender_id: nomis_offender_ids, active: true).map do |a|
      [
        a[:nomis_offender_id],
        a
      ]
    end.to_h
  end

  def self.create_allocation_override(params)
    AllocationOverride.create!(params)
  end
end
