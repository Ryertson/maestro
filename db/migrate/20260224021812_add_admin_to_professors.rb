class AddAdminToProfessors < ActiveRecord::Migration[8.1]
  def change
    add_column :professors, :admin, :boolean, default: false
  end
end
