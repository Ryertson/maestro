class AddCategoryToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :category, :string
  end
end
