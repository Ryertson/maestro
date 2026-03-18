class Student < ApplicationRecord
  # Tornamos opcional para permitir a importação via planilha sem erro de vínculo
  belongs_to :classroom, optional: true

  # Relacionamentos
  has_many :student_activities, dependent: :destroy
  has_many :activities, through: :student_activities
  
  has_many :attendances, dependent: :destroy
  has_many :student_points, dependent: :destroy

  has_one :student_user, dependent: :destroy # O aluno pode ter um login

  # Validações
  validates :name, presence: true
  validates :course, presence: true
  validates :grade, presence: true

  # --- Lógica de Desempenho e Analytics (MÉDIA PONDERADA POR TIPO) ---

  def average_for(classroom_id, subject_id, period_number = 1)
    # 1. Busca os bimestres ordenados por data e pega o correspondente
    all_bimesters = Bimester.order(:start_date).to_a
    target_bimester = all_bimesters[period_number - 1]

    return nil unless target_bimester && target_bimester.start_date && target_bimester.end_date

    # 2. Busca atividades no período e disciplina
    # Se subject_id for nil, ele busca todas as atividades da turma no período
    query = { classroom_id: classroom_id, date: target_bimester.start_date..target_bimester.end_date }
    query[:subject_id] = subject_id if subject_id.present?
    
    activities_in_period = Activity.where(query)

    return nil if activities_in_period.empty?

    # 3. Agrupamento por tipo (Prova, Trabalho, etc)
    grouped_activities = activities_in_period.group_by(&:activity_type)
    category_averages = []

    grouped_activities.each do |_type, type_activities|
      type_points = type_activities.map do |act|
        point_record = student_points.find_by(activity_id: act.id)
        # LÓGICA DE ZERO: Se não houver nota lançada, conta como 0.0
        point_record ? point_record.points.to_f : 0.0
      end
      # Média da categoria (Ex: soma das 3 listas / 3)
      category_averages << (type_points.sum / type_activities.size)
    end

    return 0.0 if category_averages.empty?
    
    # Média Final: (Média Tipo A + Média Tipo B) / Quantidade de Tipos
    (category_averages.sum / category_averages.size).round(2)
  end

  def status_for(classroom_id, subject_id = nil, period_number = 1)
    avg = average_for(classroom_id, subject_id, period_number)
    return "Pendente" if avg.nil?
    avg >= 6.0 ? "Aprovado" : "Reprovado"
  end

  # Define se o aluno está em situação de risco pedagógico
  def at_risk?(classroom_id = nil)
    return false unless student_activities.any?

    # 1. Risco por falta de entrega (menos de 50%)
    perf_baixa = activity_performance < 50

    # 2. Risco por nota baixa (Média menor que 5.0 no 1º bimestre por padrão)
    cid = classroom_id || self.classroom_id
    avg_score = average_for(cid, nil, 1).to_f
    nota_baixa = avg_score > 0 && avg_score < 5.0

    perf_baixa || nota_baixa
  end

  # --- Métodos de Apoio ---

  def activity_performance
    total = student_activities.count
    return 0 if total.zero?
    delivered = student_activities.where(status: ['Entregue', 'Entregue com Atraso']).count
    ((delivered.to_f / total) * 100).round
  end

  def activity_frequency
    total_activities = Activity.count
    return 0 if total_activities == 0
    entregues = student_activities.where(status: ["Entregue", "Entregue com Atraso"]).count
    ((entregues.to_f / total_activities) * 100).round
  end

  # ATUALIZADO: Agora suporta períodos específicos para o Assistente IA
  def attendance_percentage(range_type = :annual, classroom_id = nil)
    target_classroom = classroom_id ? Classroom.find_by(id: classroom_id) : self.classroom
    return 0 if target_classroom.nil?

    # Determina a data de início baseada no filtro
    start_date = case range_type
                 when :weekly  then Time.zone.now.beginning_of_week
                 when :monthly then Time.zone.now.beginning_of_month
                 when :bimester
                   # Pega o bimestre atual baseado na data de hoje
                   current_b = Bimester.where("start_date <= ?", Date.today).order(start_date: :desc).first
                   current_b ? current_b.start_date : Time.zone.now.beginning_of_year
                 else Time.zone.now.beginning_of_year
                 end

    # Conta apenas as aulas que já aconteceram e possuem chamada registrada
    lessons_in_range = target_classroom.lessons.where(date: start_date..Time.zone.now)
    total_lessons = lessons_in_range.count
    return 0 if total_lessons == 0

    positive_statuses = ["Presente", "presente", "Atrasado", "atrasado", "Justificada", "justificada"]
    presences = attendances.where(lesson_id: lessons_in_range.ids, status: positive_statuses).count
    
    ((presences.to_f / total_lessons) * 100).round(1)
  end

  # NOVO: Calcula a média da turma para comparação nos cards
  def classroom_attendance_avg(range_type = :annual, classroom_id)
    target_classroom = Classroom.find_by(id: classroom_id)
    return 0 if target_classroom.nil? || target_classroom.students.empty?

    all_percentages = target_classroom.students.map do |s| 
      s.attendance_percentage(range_type, classroom_id) 
    end
    
    (all_percentages.sum / all_percentages.size).round(1)
  end

  def attendance_color_class
    percent = attendance_percentage
    return "bg-danger" if percent < 50
    return "bg-warning" if percent < 75
    "bg-success"
  end

    # app/models/student.rb
  def calcular_nota_com_pesos(activities_ids)
    # Busca apenas as pontuações do aluno que estão nas atividades daquela turma/disciplina
    scores = student_points.where(activity_id: activities_ids).joins(:activity)
  
    return 0.0 if scores.empty?

    elementos_media_final = []

    # 1. Grupo Lista de Exercícios
    listas = scores.where(activities: { activity_type: "Lista de Exercícios" })
    elementos_media_final << listas.average(:points).to_f if listas.any?

    # 2. Grupo Visto
    vistos = scores.where(activities: { activity_type: "Visto" })
    elementos_media_final << vistos.average(:points).to_f if vistos.any?

    # 3. Outras Atividades (tudo que não é Lista nem Visto)
    outras = scores.where.not(activities: { activity_type: ["Lista de Exercícios", "Visto"] })
    outras.each { |s| elementos_media_final << s.points.to_f }

    return 0.0 if elementos_media_final.empty?

    # Média final dos blocos
    (elementos_media_final.sum / elementos_media_final.size).round(1)
  end
end