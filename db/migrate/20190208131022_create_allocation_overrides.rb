class CreateAllocationOverrides < ActiveRecord::Migration[5.2]
  def change
    create_table :allocation_overrides do |t|
      t.string :nomis_staff_id
      t.integer :nomis_offender_id
      t.string :override_reason
      t.string :more_detail
    end
  end
end
