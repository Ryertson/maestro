class AddUserToTeachers < ActiveRecord::Migration[8.1]
  def change
    # Trocamos 'add_reference' por 'add_column' para ser mais direto e evitar o erro de tabela inexistente
    add_column :teachers, :user_id, :integer
    add_index :teachers, :user_id
  end
end

