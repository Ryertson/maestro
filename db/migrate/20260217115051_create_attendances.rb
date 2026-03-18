class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :student, null: false, foreign_key: true
      t.date :date
      t.integer :status

      t.timestamps
    end
  end
end
