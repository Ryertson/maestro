class Activity < ApplicationRecord
  # 1. Relacionamentos
  belongs_to :classroom
  belongs_to :lesson, optional: true # Vinculado ao Tópico do Planejamento
  belongs_to :subject, optional: true
  
  has_many :student_activities, dependent: :destroy
  has_many :students, through: :student_activities
  has_many :grades, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :student_points, dependent: :destroy
  has_many :students, through: :student_points

  # 2. Constantes e Tipos
  # Definindo os novos tipos solicitados para o sistema Maestro
  TYPES = [
    "Avaliação", "Trabalho", "Visto", "Redação", 
    "Relatório Experimental", "Relatório", "Apresentação", 
    "Apresentação em Grupo", "Lista de Exercícios", 
    "Avaliação Parcial", "Avaliação Global"
  ].freeze

  # 3. Validações
  # Mantendo :name (Título) e :date (Data de Entrega) conforme seu banco original
  validates :name, :date, :points, :classroom_id, :activity_type, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :activity_type, inclusion: { in: TYPES }

  # 4. Escopos (Scopes) para os quadros de Pendências e Histórico
  scope :por_turma, ->(ids) { where(classroom_id: ids) }
  scope :pendentes, -> { where("date >= ?", Date.today) }
  scope :historico, -> { where("date < ?", Date.today) }

  # 5. Automação: Ao criar a atividade, gera o registro 'Pendente' para todos os alunos da turma
  after_create :assign_to_all_students

  # 6. Lógica de Status para o Painel de Lançamento (Etiquetas de Cores)
  def status_info_for(student)
    sa = student_activities.find_by(student_id: student.id)
    today = Date.today
    deadline = date

    # Retorno: [Texto da Etiqueta, Classe CSS do Bootstrap]
    if sa.present?
      case sa.status
      when 'Entregue'
        if sa.delivered_at.present? && sa.delivered_at > deadline
          ["Entregue Atrasado", "warning"]
        else
          ["Entregue", "success"]
        end
      when 'Não Entregue'
        ["Não Entregue", "danger"]
      when 'Pendente'
        today > deadline ? ["Não Entregue", "danger"] : ["Pendente", "secondary"]
      else
        [sa.status, "info"]
      end
    else
      today > deadline ? ["Não Entregue", "danger"] : ["Pendente", "secondary"]
    end
  end

  # Auxiliar para o quadro de Pendências: Quantitativo de alunos
  def engagement_count
    total = classroom.students.count
    entregues = student_activities.where(status: 'Entregue').count
    "#{entregues}/#{total}"
  end

  # Auxiliar para saber se a atividade já foi totalmente corrigida
  def corrected?
    # Se houver notas lançadas para pelo menos 80% da turma, consideramos encaminhada
    return false if classroom.students.empty?
    (student_activities.where.not(points: nil).count.to_f / classroom.students.count) >= 0.8
  end

  private

  # Cria o vínculo inicial para todos os alunos da turma assim que a atividade é salva
  def assign_to_all_students
    classroom.students.each do |student|
      StudentActivity.create!(
        student: student,
        activity: self,
        status: 'Pendente'
      )
    end
  end
end