class CreateTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :terms do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.string :color

      t.timestamps
    end
  end
end
