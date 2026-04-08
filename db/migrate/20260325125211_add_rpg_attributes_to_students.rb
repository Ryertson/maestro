class AddRpgAttributesToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :xp, :integer, default: 0          # XP atual do nível
    add_column :students, :level, :integer, default: 1       # Nível atual
    add_column :students, :title, :string, default: "Iniciante"
    
    # Campo extra opcional para histórico/ranking
    add_column :students, :total_xp, :integer, default: 0    
  end
end
