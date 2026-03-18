class ChangeStatusTypeInAttendances < ActiveRecord::Migration[7.1]
  def change
    # Muda a coluna de integer para string
    change_column :attendances, :status, :string
  end
end