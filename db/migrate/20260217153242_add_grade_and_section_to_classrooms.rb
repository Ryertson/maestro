class AddGradeAndSectionToClassrooms < ActiveRecord::Migration[8.1]
  def change
    add_reference :classrooms, :grade, null: false, foreign_key: true
    add_reference :classrooms, :section, null: false, foreign_key: true
  end
end
