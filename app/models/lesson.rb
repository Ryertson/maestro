class Lesson < ApplicationRecord
  # 1. ASSOCIAÇÕES
  has_and_belongs_to_many :classrooms
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
  # Atualizado: Removemos o :classroom_id estrito daqui e passamos para uma validação condicional customizada abaixo.
  validates :topic_name, :status, :date, presence: true
  validate :must_have_at_least_one_classroom

  # 4. CALLBACKS
  # Unificamos a sincronização no before_validation para evitar erros de "classroom missing"
  before_validation :sync_data_to_activities

  # Escopo para encontrar a aula do dia (Útil para chamadas e calendários)
  scope :do_dia, ->(data, classroom_id) { where(date: data, classroom_id: classroom_id) }

  # 5. MÉTODOS DE SUPORTE
  def teacher_display_name
    # Fallback seguro: se não houver relacionamento direto singular antigo, tenta buscar da primeira turma da lista.
    fallback_classroom = classroom_id.present? ? Classroom.find_by(id: classroom_id) : classrooms.first
    teacher&.name || fallback_classroom&.teachers&.first&.name || "Não atribuído"
  end

  private

  # Validação customizada para garantir que a aula tenha ao menos uma turma associada,
  # aceitando tanto o formato novo (múltiplas) quanto o antigo (campo classroom_id preenchido).
  def must_have_at_least_one_classroom
    if classrooms.blank? && classroom_id.blank?
      errors.add(:base, "A aula deve possuir pelo menos uma turma associada.")
    end
  end

  # Este método garante que a atividade criada herde o ID da turma e a data da aula,
  # evitando que fiquem "órfãs" ou com datas divergentes.
  # Só executa se houver atividades presentes para evitar erros em aulas sem atividade.
  def sync_data_to_activities
    if activities.any?
      activities.each do |activity|
        # Define qual o ID da turma a ser herdado pela atividade (prioriza o modelo novo ou o fallback antigo)
        target_classroom_id = self.classroom_id.present? ? self.classroom_id : self.classroom_ids.first
        
        activity.classroom_id = target_classroom_id if target_classroom_id.present?
        activity.date = self.date if self.date.present?
      end
    end
  end
end