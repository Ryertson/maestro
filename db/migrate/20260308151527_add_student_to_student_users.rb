class AddStudentToStudentUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :student_users, :student, null: false, foreign_key: true
  end
end
