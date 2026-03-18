class FixGradesTable < ActiveRecord::Migration[7.0]
  def change
    # Adicionamos as colunas, mas SEM o 'null: false' por enquanto
    add_column :grades, :value, :decimal, precision: 5, scale: 2
    add_reference :grades, :student, foreign_key: true
    add_reference :grades, :activity, foreign_key: true
    add_reference :grades, :bimester, foreign_key: true
  end
end
