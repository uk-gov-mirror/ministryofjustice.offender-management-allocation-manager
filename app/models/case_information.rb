# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  attr_accessor :last_known_address

  belongs_to :local_divisional_unit, optional: true
  belongs_to :team, optional: true
  has_many :early_allocations,
           foreign_key: :nomis_offender_id,
           primary_key: :nomis_offender_id,
           inverse_of: :case_information,
           dependent: :destroy

  # We only normally show/edit the most recent early allocation
  def latest_early_allocation
    early_allocations.last
  end

  validates :last_known_address, inclusion: {
    in: %w[Yes No],
    allow_nil: false,
    message: "Select yes if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
  }

  validates :manual_entry, inclusion: { in: [true, false], allow_nil: false }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :local_divisional_unit,
            presence: { message: 'You must select the prisoner’s Local Divisional Unit (LDU)' },
            unless:
            proc { |c|
              c.probation_service == 'Scotland' ||
              c.probation_service == 'Northern Ireland' ||
              c.manual_entry == false
            }

  validates :team, presence: true, unless: -> { manual_entry }

  validates :welsh_offender, inclusion: {
    in: %w[Yes No],
    allow_nil: false,
    message: 'Select yes if the prisoner’s last known address was in Wales'
  }

  validates :probation_service, inclusion: {
    in: ['Scotland', 'Northern Ireland', 'Wales', 'England'],
    allow_nil: false,
    message: "You must say if the prisoner's last known address was in Northern Ireland, Scotland or Wales"
  }

  validates :tier, inclusion: { in: %w[A B C D N/A], message: 'Select the prisoner’s tier' }

  validates :case_allocation, inclusion: {
    in: %w[NPS CRC N/A],
    allow_nil: false,
    message: 'Select the service provider for this case'
  }

  # nil means MAPPA level is completely unknown.
  # 0 means MAPPA level is known to be not relevant for offender
  validates :mappa_level, inclusion: { in: [0, 1, 2, 3], allow_nil: true }

  acts_as_gov_uk_date :parole_review_date

  validates :parole_review_date, date: { after: proc { Date.yesterday }, allow_nil: true }
end
