class AddClassroomToGrades < ActiveRecord::Migration[8.0]
  def change
    # Permitimos null: true para que as notas antigas não travem o banco
    add_reference :grades, :classroom, null: true, foreign_key: true
  end
end
