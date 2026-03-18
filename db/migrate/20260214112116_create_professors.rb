class CreateProfessors < ActiveRecord::Migration[8.1]
  def change
    create_table :professors do |t|
      t.string :nome
      t.string :matricula

      t.timestamps
    end
  end
end
