class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.string :status
      t.string :topic_name
      t.string :week
      t.date :date
      t.string :grade_level
      t.string :class_group
      t.string :course

      t.timestamps
    end
  end
end
