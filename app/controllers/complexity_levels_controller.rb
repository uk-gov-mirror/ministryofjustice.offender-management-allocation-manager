# frozen_string_literal: true

class ComplexityLevelsController < PrisonsApplicationController
  before_action :load_offender_id

  def edit
    @prisoner = OffenderService.get_offender(@offender_id)
    @complexity = Complexity.new level: @prisoner.complexity_level
  end

  def update
    @prisoner = OffenderService.get_offender(@offender_id)
    @previous_complexity_level = @prisoner.complexity_level

    @complexity = Complexity.new(complexity_params)
    if @complexity.valid?
      HmppsApi::ComplexityApi.save(@offender_id, level: @complexity.level, username: current_user, reason: @complexity.reason)
      if @complexity.level == @previous_complexity_level
        redirect_to prison_allocation_path(nomis_offender_id: @offender_id, prison_id: @prison.code)
      else
        render :confirm_complexity_changed
      end
    else
      render :edit
    end
  end

  def complexity_params
    params.require(:complexity).permit(:level, :reason)
  end

  def load_offender_id
    @offender_id = params[:prisoner_id]
  end
end
