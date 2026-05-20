class Classroom < ApplicationRecord
  # --- RELACIONAMENTOS PRINCIPAIS ---
  belongs_to :course
  belongs_to :level
  belongs_to :section, optional: true
  belongs_to :teacher, optional: true

  # --- RELACIONAMENTOS DE DEPENDÊNCIA ---
  # Se a turma for excluída, apaga os alunos e as aulas (o que dispara a limpeza de notas e atividades)
  has_many :students, dependent: :destroy
  has_and_belongs_to_many :lessons, dependent: :destroy
  
  # Busca as atividades através das aulas
  has_many :activities, through: :lessons

  # Vínculos de professores
  has_many :teacher_assignments, dependent: :destroy
  has_many :teachers, through: :teacher_assignments

  # Vínculos de turmas
  has_many :classroom_subjects, dependent: :destroy
  has_many :subjects, through: :classroom_subjects

  # --- VALIDAÇÕES ---
  validates :course_id, :level_id, :section_id, presence: true

  # --- MÉTODOS DE EXIBIÇÃO ---

  # Nome curto (Ex: Informática - 1ª Série A)
  def display_name
    "#{course&.name} - #{level&.name} #{section&.name}"
  end

  # Nome completo (Ex: Informática - 1ª Série A)
  def full_name
    "#{course&.name} - #{level&.name} #{section&.name}"
  end

  # Nome detalhado para menus de seleção (Ex: Informática | 1ª Série - Turma A)
  def full_name_info
    "#{course&.name} | #{level&.name} - Turma #{section&.name}"
  end
end