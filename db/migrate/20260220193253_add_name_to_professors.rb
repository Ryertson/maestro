class AddNameToProfessors < ActiveRecord::Migration[8.1]
  def change
    add_column :professors, :name, :string
  end
end
