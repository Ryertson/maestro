class CreateStudentActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :student_activities do |t|
      t.references :student, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.string :status
      t.date :delivered_at

      t.timestamps
    end
  end
end
