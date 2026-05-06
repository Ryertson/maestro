class RemoveOldGradeFromClassrooms < ActiveRecord::Migration[8.1]
  def change
    remove_column :classrooms, :grade, :string # Remove a coluna antiga
  end
end
