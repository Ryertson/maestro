class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.string :name
      t.string :registration_number
      t.string :grade
      t.string :classroom
      t.string :course
      t.string :email
      t.boolean :active

      t.timestamps
    end
  end
end
