class CreateProjects < ActiveRecord::Migration[5.1]
  def change
    create_table :projects do |t|
      t.string :project_name
      t.string :db_name
      t.string :env
      t.string :storage
      t.integer :vcpu
      t.string :memory
      t.string :exp_date
      t.integer :user_id
      t.timestamps
    end
  end
end
