class AddStudentUserToStudents < ActiveRecord::Migration[8.1] # ou a versão do seu Rails
  def change
    # Remova o 'null: false' para permitir que alunos antigos existam sem usuário
    add_reference :students, :student_user, foreign_key: true
  end
end
