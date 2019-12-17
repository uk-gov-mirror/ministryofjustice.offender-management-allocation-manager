# frozen_string_literal: true

class TasksController < PrisonsApplicationController
  breadcrumb 'Case updates needed', ''

  before_action :ensure_pom
  before_action :load_pom

  def index
    offenders = @prison.allocations_for(@pom.staff_id).map(&:offender)
    sorted_tasks = sort_tasks(PomTasks.new.for_offenders(offenders))
    @pomtasks = Kaminari.paginate_array(sorted_tasks).page(page)
  end

private

  def sort_tasks(tasks)
    if params['sort'].present?
      sort_field, sort_direction = params['sort'].split.map(&:to_sym)
    else
      sort_field = :offender_name
      sort_direction = :asc
    end

    # cope with nil values by sorting using to_s - only dates and strings in these fields
    sorted_tasks = tasks.sort_by { |task| task.public_send(sort_field).to_s }
    sorted_tasks.reverse! if sort_direction == :desc

    sorted_tasks
  end

  def load_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison_id
    )
  end

  def page
    params.fetch('page', 1).to_i
  end
end
