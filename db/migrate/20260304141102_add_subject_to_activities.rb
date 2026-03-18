class AddSubjectToActivities < ActiveRecord::Migration[8.1]
  def change
    # Mudamos null: false para null: true para permitir que as atividades antigas sobrevivam
    add_reference :activities, :subject, null: true, foreign_key: true
  end
end
