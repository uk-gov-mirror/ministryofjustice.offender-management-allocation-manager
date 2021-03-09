# frozen_string_literal: true

class OverridesController < PrisonsApplicationController
  def new
    @prisoner = offender(params.require(:nomis_offender_id))
    @pom = PrisonOffenderManagerService.get_pom_at(active_prison_id, params[:nomis_staff_id])

    @override = Override.new
  end

  def create
    @override = AllocationService.create_override(override_params)

    return redirect_on_success if @override.valid?

    @prisoner = offender(override_params[:nomis_offender_id])
    @pom = PrisonOffenderManagerService.get_pom_at(
      active_prison_id, override_params[:nomis_staff_id])

    render :new
  end

private

  def offender(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def redirect_on_success
    allocation = Allocation.find_by(nomis_offender_id: override_params[:nomis_offender_id])

    if allocation.present? && allocation.active?
      redirect_to prison_confirm_reallocation_path(
        active_prison_id,
        override_params[:nomis_offender_id],
        override_params[:nomis_staff_id],
        sort: params[:sort],
        page: params[:page]
                  )
    else
      redirect_to prison_confirm_allocation_path(
        active_prison_id,
        override_params[:nomis_offender_id],
        override_params[:nomis_staff_id],
        sort: params[:sort],
        page: params[:page]
                  )
    end
  end

  def override_params
    params.require(:override).permit(
      :nomis_offender_id,
      :nomis_staff_id,
      :more_detail,
      :suitability_detail,
      override_reasons: []
    )
  end
end
