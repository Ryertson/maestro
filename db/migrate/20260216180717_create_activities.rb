class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :name
      t.string :activity_type
      t.date :student_delivery_date
      t.date :teacher_delivery_date
      t.string :status
      t.decimal :grade

      t.timestamps
    end
  end
end
