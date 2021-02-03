class AddTimestampToVersions < ActiveRecord::Migration[6.0]
  def change
    change_table :versions do |t|
      t.datetime :timestamp
    end
  end
end
