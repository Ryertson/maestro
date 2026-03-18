class AddTeacherToLessons < ActiveRecord::Migration[7.1]
  def change
    # Removemos as restrições rígidas para permitir que aulas antigas sobrevivam
    add_reference :lessons, :teacher, null: true, foreign_key: true
  end
end
