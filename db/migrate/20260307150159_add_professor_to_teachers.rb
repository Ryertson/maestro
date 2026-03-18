class AddProfessorToTeachers < ActiveRecord::Migration[8.1]
  def change
    # Alteramos para null: true para permitir que registros antigos sobrevivam à migração
    add_reference :teachers, :professor, null: true, foreign_key: true
  end
end
