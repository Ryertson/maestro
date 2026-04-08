class CreateStudentBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :student_badges do |t|
      t.references :student, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.datetime :granted_at

      t.timestamps
    end
  end
end
