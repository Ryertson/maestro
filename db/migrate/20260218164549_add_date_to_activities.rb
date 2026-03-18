class AddDateToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :date, :date
  end
end
