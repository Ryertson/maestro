class StudentPoint < ApplicationRecord
  belongs_to :student
  belongs_to :activity

  validates :points, numericality: { greater_than_or_equal_to: 0 }
end
