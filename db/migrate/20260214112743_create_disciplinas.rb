class CreateDisciplinas < ActiveRecord::Migration[8.1]
  def change
    create_table :disciplinas do |t|
      t.string :nome
      t.string :area
      t.integer :carga_horaria
      t.references :professor, null: false, foreign_key: true

      t.timestamps
    end
  end
end
