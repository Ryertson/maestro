class AddCorrectedToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :corrected, :boolean
  end
end
