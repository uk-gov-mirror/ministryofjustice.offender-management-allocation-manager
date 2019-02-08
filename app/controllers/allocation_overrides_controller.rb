class AllocationOverridesController < ApplicationController
  before_action :authenticate_user

  def new
    @prisoner = prisoner
    @recommended_pom = @prisoner.current_responsibility
    @allocation_override = AllocationService.get_override_instance

    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select {|p| p.staff_id == params.require(:nomis_staff_id)}.first
  end

  def create
    byebug
    AllocationService.get_override_instance.save!(
      nomis_staff_id: allocation_override_params[:nomis_staff_id],
      nomis_offender_id: allocation_override_params[:nomis_offender_id],
      override_reason: allocation_override_params[:override_reason],
      more_detail: allocation_override_params[:more_detail]
    )



    redirect_to allocate_new_path(nomis_offender_id, nomis_staff_id)
  end

  private

  def prisoner
    OffenderService.new.get_offender(params.require(:nomis_offender_id)).data
  end

  def allocation_override_params
    params.require(:allocation_override).permit(
      :nomis_offender_id, :nomis_staff_id, :override_reason, :more_detail
    )
  end
end
