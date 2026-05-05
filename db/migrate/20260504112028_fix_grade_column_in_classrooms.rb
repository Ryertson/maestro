class FixGradeColumnInClassrooms < ActiveRecord::Migration[8.1]
  def change
    rename_column :classrooms, :grade_id, :level_id
  end
end
