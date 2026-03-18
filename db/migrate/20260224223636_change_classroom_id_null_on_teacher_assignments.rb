class ChangeClassroomIdNullOnTeacherAssignments < ActiveRecord::Migration[8.1]
  def change
    # Permite que classroom_id e course_id sejam nulos no banco de dados
    change_column_null :teacher_assignments, :classroom_id, true
    change_column_null :teacher_assignments, :course_id, true
  end
end
