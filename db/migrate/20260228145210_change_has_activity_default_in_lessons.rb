class ChangeHasActivityDefaultInLessons < ActiveRecord::Migration[8.1]
  def change
    change_column_default :lessons, :has_activity, from: nil, to: false
  end
end
