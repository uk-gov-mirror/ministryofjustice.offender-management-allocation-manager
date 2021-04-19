class AddPrisonIdToPomDetail < ActiveRecord::Migration[6.0]
  def change
    change_table :pom_details do |t|
      t.string :prison_code, length: 3
    end
    remove_index :pom_details, :nomis_staff_id
    add_index :pom_details, [:nomis_staff_id, :prison_code], unique: true
  end
end
