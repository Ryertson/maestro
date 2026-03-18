class StudentActivity < ApplicationRecord
  belongs_to :student
  belongs_to :activity

  after_save :sync_with_grades

  STATUSES = ['Pendente', 'Entregue', 'Entregue com Atraso', 'Não Entregue'].freeze
  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  private

  def sync_with_grades
    # Aqui o erro acontece porque course_id não existe em 'grades'
    # Vamos mudar para classroom_id, que é o padrão que estamos usando
    grade = Grade.find_or_initialize_by(
      student_id: self.student_id,
      # Se a tabela grades não tiver course_id, use classroom_id:
      classroom_id: self.activity.classroom_id 
    )
  
    # Atualiza o valor da nota geral (isso depende da sua lógica de média)
    # Por enquanto, vamos apenas garantir que o erro de coluna pare:
    grade.value = self.points
    grade.save
  end
end
