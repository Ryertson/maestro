class Grade < ApplicationRecord
  belongs_to :student
  belongs_to :subject
  # Adicione esta linha:
  belongs_to :classroom, optional: true 
end
