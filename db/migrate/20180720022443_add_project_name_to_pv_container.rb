class AddProjectNameToPvContainer < ActiveRecord::Migration[5.1]
  def change
    add_column :pv_containers, :project_name, :string
  end
end
