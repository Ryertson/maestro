class AddTeacherToClassrooms < ActiveRecord::Migration[8.0]
  def change
    # Mudamos para null: true para permitir turmas sem professor por enquanto
    add_reference :classrooms, :teacher, null: true, foreign_key: true
  end
end
