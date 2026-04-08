class CreateBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :badges do |t|
      t.string :name
      t.text :description
      t.string :icon
      t.string :category

      t.timestamps
    end
  end
end
