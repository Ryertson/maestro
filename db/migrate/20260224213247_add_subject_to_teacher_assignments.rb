class AddSubjectToTeacherAssignments < ActiveRecord::Migration[8.0]
  def change
    # Removemos o 'null: false' para o banco aceitar a criação da coluna
    add_reference :teacher_assignments, :subject, null: true, foreign_key: true
  end
end
