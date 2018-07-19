class CreatePvContainers < ActiveRecord::Migration[5.1]
  def change
    create_table :pv_containers do |t|
      t.string :pv_name
      t.integer :pv_used

      t.timestamps
    end
  end
end
