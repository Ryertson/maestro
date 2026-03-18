class Lesson < ApplicationRecord
  # 1. ASSOCIAÇÕES
  belongs_to :classroom
  belongs_to :teacher, optional: true
  belongs_to :subject, optional: true
  
  # A relação com activities permite criar, editar e excluir através da aula
  has_many :activities, dependent: :destroy
  has_many :attendances, dependent: :destroy

  # Permite que o formulário da aula envie dados para a atividade simultaneamente
  # O reject_if garante que se o interruptor estiver desligado (nome vazio), 
  # a atividade seja ignorada e a aula seja salva sozinha.
  accepts_nested_attributes_for :activities, 
    allow_destroy: true, 
    reject_if: proc { |attributes| attributes['name'].blank? }

  # 2. ENUMS
  enum :status, {
    não_iniciada: "não_iniciada",
    preparando: "preparando",
    pronto: "pronto"
  }

  # 3. VALIDAÇÕES
  validates :topic_name, :status, :date, :classroom_id, presence: true

  # 4. CALLBACKS
  # Unificamos a sincronização no before_validation para evitar erros de "classroom missing"
  before_validation :sync_data_to_activities

  # Escopo para encontrar a aula do dia (Útil para chamadas e calendários)
  scope :do_dia, ->(data, classroom_id) { where(date: data, classroom_id: classroom_id) }

  # 5. MÉTODOS DE SUPORTE
  def teacher_display_name
    teacher&.name || classroom.teachers.first&.name || "Não atribuído"
  end

  private

  # Este método garante que a atividade criada herde o ID da turma e a data da aula,
  # evitando que fiquem "órfãs" ou com datas divergentes.
  # Só executa se houver atividades presentes para evitar erros em aulas sem atividade.
  def sync_data_to_activities
    if activities.any?
      activities.each do |activity|
        # Só atribuímos se a aula já tiver esses dados
        activity.classroom_id = self.classroom_id if self.classroom_id.present?
        activity.date = self.date if self.date.present?
      end
    end
  end
end