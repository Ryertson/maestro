class AddHasActivityToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :has_activity, :boolean
  end
end
