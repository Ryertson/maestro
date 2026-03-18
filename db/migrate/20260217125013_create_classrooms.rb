class CreateClassrooms < ActiveRecord::Migration[8.1]
  def change
    create_table :classrooms do |t|
      t.string :grade
      t.string :section
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
