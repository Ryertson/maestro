class Subject < ApplicationRecord
  belongs_to :knowledge_area
  has_and_belongs_to_many :teachers
end
