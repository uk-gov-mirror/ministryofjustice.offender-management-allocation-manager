# frozen_string_literal: true

class PomDetail < ApplicationRecord
  validates :nomis_staff_id, presence: true, uniqueness: { scope: :prison_code }
  validates :status, presence: true
  validates :working_pattern, presence: {
    message: 'Select number of days worked'
  }
  validates_presence_of :prison_code

  def allocations
    offender_ids = Prison.new(prison_code).offenders.map(&:offender_no)
    Allocation.active_pom_allocations(nomis_staff_id, prison_code).where(nomis_offender_id: offender_ids)
  end
end
