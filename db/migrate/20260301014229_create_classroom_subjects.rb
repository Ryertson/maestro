class CreateClassroomSubjects < ActiveRecord::Migration[8.1]
  def change
    create_table :classroom_subjects do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true

      t.timestamps
    end
  end
end
