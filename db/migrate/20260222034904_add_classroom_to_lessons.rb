class AddClassroomToLessons < ActiveRecord::Migration[8.1]
  def change
    add_reference :lessons, :classroom, foreign_key: true
  end
end
