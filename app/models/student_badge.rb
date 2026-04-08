class StudentBadge < ApplicationRecord
  belongs_to :student
  belongs_to :badge
end
