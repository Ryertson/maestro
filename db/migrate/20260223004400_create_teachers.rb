class CreateTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :teachers do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.text :bio
      t.string :status

      t.timestamps
    end
  end
end
