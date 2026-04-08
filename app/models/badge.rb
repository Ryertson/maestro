class Badge < ApplicationRecord
  has_many :student_badges, dependent: :destroy
  has_many :students, through: :student_badges

  validates :name, :category, presence: true
end
