class CreateAcademicEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_events do |t|
      t.string :title
      t.date :event_date
      t.string :event_type
      t.string :color

      t.timestamps
    end
  end
end
