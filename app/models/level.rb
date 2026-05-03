class Level < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  # Adicione esta linha:
  belongs_to :classroom, optional: true 
end
