class Teacher < ApplicationRecord
  # Relacionamento com o login do sistema
  belongs_to :user, optional: true
  belongs_to :professor, optional: true
  
  # --- RELACIONAMENTOS DE ALOCAÇÃO (Botão Disciplinas na Turma) ---
  # Esta é a estrutura que usamos para o vínculo real de aulas
  has_many :classroom_subjects, dependent: :destroy
  has_many :classrooms, -> { distinct }, through: :classroom_subjects
  
  # --- RELACIONAMENTOS DE COMPETÊNCIA (Áreas de Atuação no Perfil) ---
  # Usamos teacher_assignments para listar o que o professor SABE ensinar
  has_many :teacher_assignments, dependent: :destroy
  has_many :subjects, through: :teacher_assignments
  
  # Aceita atributos aninhados para evitar erros de validação ao atualizar o perfil
  accepts_nested_attributes_for :teacher_assignments, allow_destroy: true
  # ------------------------------------------------------------------------------

  # Busca as lições através das turmas vinculadas
  has_many :lessons, through: :classrooms

  # Validações
  validates :user_id, uniqueness: { 
    message: "já possui um perfil de professor vinculado.", 
    allow_nil: true 
  }
  validates :name, presence: true

  # --- MÉTODOS AUXILIARES ---

  # Retorna as iniciais para o Avatar (ex: "Ryertson Silva" -> "RS")
  def initials
    return "??" if name.blank?
    name.split.map(&:first).join.upcase.first(2)
  end

  # Vincula o perfil ao usuário logado de forma segura
  def link_to_user(user)
    return false if user.nil?
    
    # Se já estiver vinculado a outro usuário, impede a troca acidental
    return false if self.user_id.present? && self.user_id != user.id

    self.user_id = user.id
    save
  end

    # Retorna uma lista legível de todas as disciplinas (Atuação + Alocação)
  def all_subjects_names
    # Pega os nomes das áreas de atuação e das disciplinas vinculadas a turmas
    names = (subjects.pluck(:name) + classroom_subjects.map { |cs| cs.subject.name }).uniq
    names.any? ? names.join(", ") : "Geral (Não vinculada)"
  end

  # Método para contar turmas alocadas de forma única
  def allocated_classrooms_count
    classrooms.count
  end
end