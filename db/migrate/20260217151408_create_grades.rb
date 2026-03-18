class CreateGrades < ActiveRecord::Migration[8.1]
  def change
    create_table :grades do |t|
      t.string :name

      t.timestamps
    end
  end
end
