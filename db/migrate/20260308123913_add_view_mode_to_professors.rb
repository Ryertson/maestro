class AddViewModeToProfessors < ActiveRecord::Migration[8.1]
  def change
    # Adiciona a coluna view_mode com o valor padrão 0 (Modo Professor)
    add_column :professors, :view_mode, :integer, default: 0
  end
end
