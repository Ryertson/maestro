# app/models/grade.rb
class Grade < ApplicationRecord
  belongs_to :student
  belongs_to :subject
  belongs_to :classroom

  # Validação para evitar que o erro de 'nil' volte na view
  validates :student_id, :subject_id, :classroom_id, presence: true
end