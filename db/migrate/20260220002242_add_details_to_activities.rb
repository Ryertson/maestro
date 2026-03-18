class AddDetailsToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :points, :integer
    add_reference :activities, :lesson, null: false, foreign_key: true
  end
end
