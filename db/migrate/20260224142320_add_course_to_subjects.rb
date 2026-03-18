class AddCourseToSubjects < ActiveRecord::Migration[7.1]
  def change
    # Removemos o null: false para permitir que disciplinas antigas sobrevivam
    add_reference :subjects, :course, null: true, foreign_key: true
  end
end
