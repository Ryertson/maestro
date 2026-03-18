class AddSubjectToLessons < ActiveRecord::Migration[8.1]
  def change
    # Adicionamos permitindo null para não quebrar as aulas antigas
    add_reference :lessons, :subject, null: true, foreign_key: true
  end
end
