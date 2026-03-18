class CreateKnowledgeAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_areas do |t|
      t.string :name
      t.string :color

      t.timestamps
    end
  end
end
