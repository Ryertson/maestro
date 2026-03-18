class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :title
      t.integer :schedule
      t.integer :day_of_week
      t.string :subject_name

      t.timestamps
    end
  end
end
