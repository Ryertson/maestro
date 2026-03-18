class AddFieldsToStudentActivities < ActiveRecord::Migration[8.0]
  def change
    # Verificamos se a coluna não existe antes de tentar adicionar
    unless column_exists?(:student_activities, :delivered_at)
      add_column :student_activities, :delivered_at, :date
    end

    unless column_exists?(:student_activities, :points)
      add_column :student_activities, :points, :decimal, precision: 5, scale: 2
    end
    
    # Se você já tem o status, não precisamos da linha do status aqui.
  end
end
