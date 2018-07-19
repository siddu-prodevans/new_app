class CreateOcPvcs < ActiveRecord::Migration[5.1]
  def change
    create_table :oc_pvcs do |t|
      t.integer :project_id
      t.string :pvc_name
      t.integer :used_pv

      t.timestamps
    end
  end
end
