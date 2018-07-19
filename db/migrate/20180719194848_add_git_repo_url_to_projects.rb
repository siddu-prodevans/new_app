class AddGitRepoUrlToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :git_repo_url, :string
  end
end
