class AddLevelIdToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :level_id, :integer
  end
end
