class AddScoreToStudentActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :student_activities, :score, :float
  end
end
