class Subject < ApplicationRecord
  belongs_to :knowledge_area
  has_and_belongs_to_many :teachers
  has_many :classroom_subjects
  has_many :classrooms, through: :classroom_subjects
end
