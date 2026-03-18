class AddClassroomToStudents < ActiveRecord::Migration[8.1]
  def change
    add_reference :students, :classroom, null: false, foreign_key: true
  end
end
