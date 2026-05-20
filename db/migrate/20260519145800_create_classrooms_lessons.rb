class CreateClassroomsLessons < ActiveRecord::Migration[8.1]
  def change
    create_join_table :classrooms, :lessons do |t|
      t.index [:classroom_id, :lesson_id]
      t.index [:lesson_id, :classroom_id]
    end
  end
end
