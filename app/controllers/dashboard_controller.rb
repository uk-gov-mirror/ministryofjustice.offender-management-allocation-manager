# frozen_string_literal: true

class DashboardController < PrisonsApplicationController

  def index
    @is_pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user, active_prison
    ).present?
  end

end
