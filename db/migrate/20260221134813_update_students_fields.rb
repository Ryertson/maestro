class UpdateStudentsFields < ActiveRecord::Migration[8.1]
  def change
    # Só adiciona se a coluna NÃO existir
    add_column :students, :course, :string unless column_exists?(:students, :course)
    add_column :students, :grade, :string unless column_exists?(:students, :grade)
    add_column :students, :section, :string unless column_exists?(:students, :section)

    # Remove os campos antigos (se eles existirem)
    remove_column :students, :registration_number, :string if column_exists?(:students, :registration_number)
    remove_column :students, :contact_email, :string if column_exists?(:students, :contact_email)
  end
end