class AddLessonAndClassroomToAttendances < ActiveRecord::Migration[7.1]
  def change
    # Removemos o 'null: false' para evitar o erro de Constraint
    add_reference :attendances, :lesson, null: true, foreign_key: true
    add_reference :attendances, :classroom, null: true, foreign_key: true
  end
end
