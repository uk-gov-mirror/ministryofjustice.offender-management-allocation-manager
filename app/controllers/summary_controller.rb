# frozen_string_literal: true

class SummaryController < PrisonersController
  before_action :ensure_spo_user

  before_action :set_search_summary_data, only: :search

  def allocated
    summary = create_summary(:allocated)
    set_data(summary)
  end

  def unallocated
    summary = create_summary(:unallocated)
    set_data(summary)
  end

  def missing_information
    summary = create_summary(:missing_information)
    set_data(summary)
  end

  def new_arrivals
    summary = create_summary(:new_arrivals)
    set_data(summary)
  end

  def search
    super
  end

private

  def set_search_summary_data
    # pick an abrbitrary summary type
    summary = create_summary(:new_arrivals)

    # Populate fields required for search.html.erb
    @allocated = summary.allocated
    @unallocated = summary.unallocated
    @missing_info = summary.pending
    @new_arrivals = summary.new_arrivals
  end

  def set_data(summary)
    @allocated = summary.allocated
    @unallocated = summary.unallocated
    @missing_info = summary.pending
    @new_arrivals = summary.new_arrivals

    @offenders = Kaminari.paginate_array(summary.offenders.to_a).page(page)
  end

  def create_summary(summary_type)
    SummaryService.new(summary_type, @prison, params['sort'])
  end
end
