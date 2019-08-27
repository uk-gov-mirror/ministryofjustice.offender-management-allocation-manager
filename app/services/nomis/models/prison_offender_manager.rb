# frozen_string_literal: true

module Nomis
  module Models
    class PrisonOffenderManager
      include MemoryModel

      attribute :staff_id, :integer
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :agency_id, :string
      attribute :agency_description, :string
      attribute :from_date, :date
      attribute :position, :string
      attribute :position_description, :string
      attribute :role, :string
      attribute :role_description, :string
      attribute :schedule_type, :string
      attribute :schedule_type_description, :string
      attribute :hours_per_week, :integer
      attribute :thumbnail_id, :string
      attribute :emails

      attribute :tier_a, :integer
      attribute :tier_b, :integer
      attribute :tier_c, :integer
      attribute :tier_d, :integer
      attribute :total_cases, :integer
      attribute :status, :string
      attribute :working_pattern, :string

      def full_name
        "#{last_name}, #{first_name}".titleize
      end

      def full_name_ordered
        "#{first_name} #{last_name}".titleize
      end

      def grade
        "#{position_description.split(' ').first} POM"
      end

      def add_detail(pom_detail, prison)
        allocation_counts = AllocationVersion.active_primary_pom_allocations(
          pom_detail.nomis_staff_id, prison).group(:allocated_at_tier).count

        self.tier_a = allocation_counts.fetch('A', 0)
        self.tier_b = allocation_counts.fetch('B', 0)
        self.tier_c = allocation_counts.fetch('C', 0)
        self.tier_d = allocation_counts.fetch('D', 0)
        self.total_cases = [tier_a, tier_b, tier_c, tier_d].sum
        self.status = pom_detail.status
        self.working_pattern = pom_detail.working_pattern
      end
    end
  end
end
