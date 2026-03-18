class Attendance < ApplicationRecord
  belongs_to :student
  belongs_to :lesson, optional: true
  belongs_to :classroom, optional: true

  # Lista de status permitidos (incluindo as versões em português para a barra de frequência)
  validates :status, inclusion: { in: ["Presente", "Faltou", "Atrasado", "Justificada", "cleared"] }
end
