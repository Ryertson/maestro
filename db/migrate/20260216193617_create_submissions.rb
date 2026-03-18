class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :student, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
