class CreateGradesValue < ActiveRecord::Migration[8.1]
  def change
    create_table :grades do |t|
      t.decimal :value          # O valor da nota (ex: 8.5)
      t.string :period          # O bimestre/período
      t.references :student, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true

      t.timestamps
    end
  end
end
