class RemoveWelshOffenderColumn < ActiveRecord::Migration[6.0]
  def change
    change_table :case_information do |t|
      t.remove :welsh_offender
    end
  end
end
