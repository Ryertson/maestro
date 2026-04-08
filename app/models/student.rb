class Student < ApplicationRecord
  # --- Configurações Iniciais e Relacionamentos ---
  
  # Tornamos opcional para permitir a importação via planilha sem erro de vínculo
  belongs_to :classroom, optional: true

  has_many :student_activities, dependent: :destroy
  has_many :activities, through: :student_activities
  has_many :student_badges, dependent: :destroy
  has_many :badges, through: :student_badges
  
  has_many :attendances, dependent: :destroy
  has_many :student_points, dependent: :destroy

  has_one :student_user, dependent: :destroy # O aluno pode ter um login

  # Validações
  validates :name, presence: true
  validates :course, presence: true
  validates :grade, presence: true

  # --- Lógica de Desempenho e Analytics ---

  def average_for(classroom_id, subject_id, period_number = 1)
    all_bimesters = Bimester.order(:start_date).to_a
    target_bimester = all_bimesters[period_number - 1]

    return nil unless target_bimester && target_bimester.start_date && target_bimester.end_date

    query = { classroom_id: classroom_id, date: target_bimester.start_date..target_bimester.end_date }
    query[:subject_id] = subject_id if subject_id.present?
    
    activities_in_period = Activity.where(query)
    return nil if activities_in_period.empty?

    grouped_activities = activities_in_period.group_by(&:activity_type)
    category_averages = []

    grouped_activities.each do |_type, type_activities|
      type_points = type_activities.map do |act|
        point_record = student_points.find_by(activity_id: act.id)
        point_record ? point_record.points.to_f : 0.0
      end
      category_averages << (type_points.sum / type_activities.size)
    end

    return 0.0 if category_averages.empty?
    (category_averages.sum / category_averages.size).round(2)
  end

  def status_for(classroom_id, subject_id = nil, period_number = 1)
    avg = average_for(classroom_id, subject_id, period_number)
    return "Pendente" if avg.nil?
    avg >= 6.0 ? "Aprovado" : "Reprovado"
  end

  def at_risk?(classroom_id = nil)
    return false unless student_activities.any?
    perf_baixa = activity_performance < 50
    cid = classroom_id || self.classroom_id
    avg_score = average_for(cid, nil, 1).to_f
    nota_baixa = avg_score > 0 && avg_score < 5.0
    perf_baixa || nota_baixa
  end

  def activity_performance
    total = student_activities.count
    return 0 if total.zero?
    delivered = student_activities.where(status: ['Entregue', 'Entregue com Atraso']).count
    ((delivered.to_f / total) * 100).round
  end

  def attendance_percentage(range_type = :annual, classroom_id = nil)
    target_classroom = classroom_id ? Classroom.find_by(id: classroom_id) : self.classroom
    return 0 if target_classroom.nil?

    start_date = case range_type
                 when :weekly  then Time.zone.now.beginning_of_week
                 when :monthly then Time.zone.now.beginning_of_month
                 when :bimester
                   current_b = Bimester.where("start_date <= ?", Date.today).order(start_date: :desc).first
                   current_b ? current_b.start_date : Time.zone.now.beginning_of_year
                 else Time.zone.now.beginning_of_year
                 end

    lessons_in_range = target_classroom.lessons.where(date: start_date..Time.zone.now)
    total_lessons = lessons_in_range.count
    return 0 if total_lessons == 0

    positive_statuses = ["Presente", "presente", "Atrasado", "atrasado", "Justificada", "justificada"]
    presences = attendances.where(lesson_id: lessons_in_range.ids, status: positive_statuses).count
    ((presences.to_f / total_lessons) * 100).round(1)
  end

  # --- SISTEMA DE RPG E GAMIFICAÇÃO ---

  def xp_needed_for_next_level
    lvl = self.level || 1
    (lvl * 100 * 1.2).to_i
  end

  def rpg_progress_percentage
    needed = xp_needed_for_next_level
    return 0 if needed.zero?
    current_xp = self.xp || 0
    ((current_xp.to_f / needed.to_f) * 100).round
  end

  def gain_xp(amount)
    self.xp ||= 0
    self.level ||= 1
    self.total_xp ||= 0

    self.total_xp += amount
    new_xp = self.xp + amount

    while new_xp >= xp_needed_for_next_level
      new_xp -= xp_needed_for_next_level
      self.level += 1
      update_rpg_title
    end
    
    self.xp = new_xp
    self.save
    check_for_new_badges
  end

  def update_rpg_title(subject_name = nil)
    subject_name ||= "Geral"
    self.title = case subject_name.downcase
                 when /química/ then titles_natureza
                 when /português|redação|inglês|espanhol|artes/ then titles_linguagens
                 when /matemática|física/ then titles_exatas
                 when /história|geografia|filosofia|sociologia/ then titles_humanas
                 else titles_geral
                 end
  end

  # --- SISTEMA DE CONQUISTAS (MEDALHAS) ---

  def check_for_new_badges
    if attendance_percentage >= 95
      award_badge("Fogo Eterno", "Assiduidade lendária com mais de 95% de presença.", "bi-fire", "Frequência")
    end

    delivered_count = student_activities.where(status: ['Entregue', 'Entregue com Atraso']).count
    if delivered_count >= 5
      award_badge("Veterano", "Mais de 5 missões concluídas no reino.", "bi-shield-check", "Atividade")
    end

    sub_quimica = Subject.where("LOWER(name) LIKE ?", "%química%").first
    if sub_quimica
      avg_q = average_for(self.classroom_id, sub_quimica.id, 1).to_f
      award_badge("Alquimista de Elite", "Mestria total nas artes da Natureza.", "bi-gem", "Desempenho") if avg_q >= 9.0
    end
  end

  # --- MÉTODO DE CÁLCULO DE MÉDIAS (SINCRONIZADO) ---

  def calcular_nota_com_pesos(activity_ids)
    # Limpeza dos IDs e remoção de duplicatas/zeros
    ids = Array(activity_ids).map(&:to_i).reject(&:zero?).uniq
    return 0.0 if ids.empty?

    # Busca as atividades solicitadas
    atividades = Activity.where(id: ids)
    
    # Mapeamento rápido: Cria um dicionário { id_da_atividade => nota_do_aluno }
    # Isso garante que o Ruby encontre a nota 10.0 do aluno 4345 instantaneamente
    pontos_map = self.student_points.where(activity_id: ids).pluck(:activity_id, :points).to_h

    vistos = []
    listas = []
    outras_atividades = []

    # Organiza as notas por categoria baseada no nome da atividade
    atividades.each do |activity|
      valor_nota = pontos_map[activity.id].to_f || 0.0
      
      nome_act = activity.name.to_s.downcase

      if nome_act.include?("visto")
        vistos << valor_nota
      elsif nome_act.include?("lista de exerc")
        listas << valor_nota
      else
        peso = activity.respond_to?(:weight) ? (activity.weight || 1.0) : 1.0
        outras_atividades << { nota: valor_nota, peso: peso }
      end
    end

    # Cálculos das Médias Aritméticas dos grupos
    media_vistos = vistos.any? ? (vistos.sum / vistos.size.to_f) : nil
    media_listas = listas.any? ? (listas.sum / listas.size.to_f) : nil

    total_notas_ponderadas = 0.0
    soma_pesos = 0.0

    # Soma atividades que não são Vistos nem Listas (Usando seus pesos individuais)
    outras_atividades.each do |item|
      total_notas_ponderadas += (item[:nota] * item[:peso])
      soma_pesos += item[:peso]
    end

    # Adiciona a média dos Vistos como uma nota única de Peso 1.0
    if media_vistos
      total_notas_ponderadas += media_vistos
      soma_pesos += 1.0
    end

    # Adiciona a média das Listas como uma nota única de Peso 1.0
    if media_listas
      total_notas_ponderadas += media_listas
      soma_pesos += 1.0
    end

    return 0.0 if soma_pesos.zero?
    (total_notas_ponderadas / soma_pesos).round(2)
  end

  private

  def award_badge(name, desc, icon, category)
    badge = Badge.find_or_create_by!(name: name) do |b|
      b.description = desc
      b.icon = icon
      b.category = category
    end
    self.badges << badge unless self.badges.include?(badge)
  end

  def titles_natureza
    case (self.level || 1)
    when 1..5   then "Elétron Livre"
    when 6..10  then "Manipulador de Reações"
    when 11..15 then "Mestre da Estequiometria"
    else "Alquimista Lendário"
    end
  end

  def titles_linguagens
    case (self.level || 1)
    when 1..5   then "Menestrel de Velastraer"
    when 6..10  then "Escriba dos Pergaminhos"
    when 11..15 then "Orador da Corte"
    else "Arquivista Real"
    end
  end

  def titles_exatas
    case (self.level || 1)
    when 1..5   then "Calculador de Rotas"
    when 6..10  then "Geômetra do Reino"
    when 11..15 then "Engenheiro de Cerco"
    else "Arquiteto do Destino"
    end
  end

  def titles_humanas
    case (self.level || 1)
    when 1..5   then "Explorador de Fronteiras"
    when 6..10  then "Diplomata das Nações"
    when 11..15 then "Estrategista de Guerra"
    else "Filósofo de Velastraer"
    end
  end

  def titles_geral
    case (self.level || 1)
    when 1..5   then "Aprendiz Iniciante"
    when 6..10  then "Aventureiro"
    when 11..15 then "Herói do Conhecimento"
    else "Guardião do Maestro"
    end
  end
end