class ClassroomSubject < ApplicationRecord
  belongs_to :classroom
  belongs_to :subject
  belongs_to :teacher
end
