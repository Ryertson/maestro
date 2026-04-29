class StudentActivity < ApplicationRecord
  belongs_to :student
  belongs_to :activity

  # Usaremos o Mapa de Pontuação para garantir que cada coluna de atividade seja preenchida
  after_save :sync_to_student_points

  STATUSES = ['Pendente', 'Entregue', 'Entregue com Atraso', 'Não Entregue'].freeze
  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  private

  def sync_to_student_points
    # 1. Procuramos o registro específico desta ATIVIDADE para este ALUNO no Mapa de Pontos
    point = StudentPoint.find_or_initialize_by(
      student_id: self.student_id,
      activity_id: self.activity_id
    )

    # 2. Espelhamos a nota lançada na atividade para o Mapa de Pontos
    point.points = self.points
    
    # 3. Salvamos. Isso fará com que o 10.0 da página de atividades apareça na página student_points
    point.save
  end
end