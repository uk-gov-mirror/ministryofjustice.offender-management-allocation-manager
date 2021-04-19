# frozen_string_literal: true

#
# The return value from get_poms_for - a combo of PomDetails and PrisonOffenderManager from the API
class PomWrapper
  delegate :position_description, :first_name, :last_name, :probation_officer?, :prison_officer?, :staff_id, :agency_id, to: :@pom
  delegate :status, :working_pattern, :allocations, to: :@pom_detail

  def initialize(pom, pom_detail)
    @pom = pom
    @pom_detail = pom_detail
  end

  def tier_a
    allocations.count { |o| o.tier == 'A' }
  end

  def tier_b
    allocations.count { |o| o.tier == 'B' }
  end

  def tier_c
    allocations.count { |o| o.tier == 'C' }
  end

  def tier_d
    allocations.count { |o| o.tier == 'D' }
  end

  def no_tier
    allocations.count { |o| o.tier == 'N/A' }
  end
end
