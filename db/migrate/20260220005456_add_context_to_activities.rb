class AddContextToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :grade_id, :integer
    add_column :activities, :course_id, :integer
  end
end
