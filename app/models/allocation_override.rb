class AllocationOverride < ApplicationRecord
  validates :nomis_offender_id, :nomis_booking_id, :override_reason, presence: true
end
