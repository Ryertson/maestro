require 'csv'

class Student < ApplicationRecord
  # --- Configurações Iniciais e Relacionamentos ---
  
  # Tornamos opcional para permitir a importação via planilha sem erro de vínculo imediato
  belongs_to :classroom, optional: true
  
  # Configuração da associação de série (Série Escolar) para não conflitar com a coluna 'level' do RPG
  belongs_to :level_association, class_name: 'Level', foreign_key: 'level_id', optional: true

  has_many :student_activities, dependent: :destroy
  has_many :activities, through: :student_activities
  has_many :student_badges, dependent: :destroy
  has_many :badges, through: :student_badges
  
  has_many :attendances, dependent: :destroy
  has_many :student_points, dependent: :destroy

  has_one :student_user, foreign_key: :email, primary_key: :email

  # Validações Atualizadas
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :course, presence: true
  # Trocamos :grade por :level_id para alinhar com o novo banco de dados Maestro
  validates :level_id, presence: true, on: :create, if: -> { self.respond_to?(:level_id) && classroom_id.blank? }

  # --- LÓGICA DE IMPORTAÇÃO DE PLANILHA (VERSÃO UNIFICADA E BLINDADA) ---

  def self.import(file)
    # col_sep: ';' -> Ajustado para o padrão de planilhas CSV brasileiras
    # encoding: 'bom|utf-8' -> Garante que acentos não quebrem a importação
    CSV.foreach(file.path, headers: true, col_sep: ';', header_converters: :symbol, encoding: 'bom|utf-8', skip_blanks: true) do |row|
      student_hash = row.to_hash
      
      # Limpeza de strings para evitar erros de comparação e e-mail
      email_limpo = student_hash[:email].to_s.strip.downcase
      next if email_limpo.blank? || student_hash[:nome_do_aluno].blank?

      # 1. Tratamento da Série (Level)
      # Busca o Level pelo nome (ex: "1ª Série") vindo da coluna :serie ou :série
      serie_name = student_hash[:serie] || student_hash[:série]
      level_id_encontrado = nil
      if serie_name.present?
        found_level = Level.find_by("LOWER(name) = ?", serie_name.to_s.strip.downcase)
        level_id_encontrado = found_level&.id
        student_hash[:level_id] = level_id_encontrado
      end

      # 2. Tratamento da Turma (Classroom) - A "Junção de Nomes"
      # Tenta localizar a Classroom correta baseada no Curso, Nível e Seção (Turma)
      if student_hash[:curso].present? && student_hash[:turma].present? && level_id_encontrado
        course_found = Course.where("LOWER(name) LIKE ?", "%#{student_hash[:curso].to_s.strip.downcase}%").first
        section_found = Section.find_by("LOWER(name) = ?", student_hash[:turma].to_s.strip.downcase)
        
        if course_found && section_found
          classroom_target = Classroom.find_by(
            course_id: course_found.id, 
            level_id: level_id_encontrado, 
            section_id: section_found.id
          )
          student_hash[:classroom_id] = classroom_target.id if classroom_target
        end
      end

      # 3. Limpeza de Atributos e Mass Assignment (PROTEÇÃO CONTRA ERRO 'GRADE')
      # Removemos chaves que não são colunas reais no banco para evitar erro de 'Unknown Attribute'
      student_hash[:name] = student_hash[:nome_do_aluno].to_s.strip if student_hash[:nome_do_aluno]
      student_hash[:email] = email_limpo
      student_hash[:course] = student_hash[:curso].to_s.strip if student_hash[:curso]
      
      # Deletamos as chaves que o CSV usa mas o Banco não possui mais
      student_hash.delete(:nome_do_aluno)
      student_hash.delete(:curso)
      student_hash.delete(:serie)
      student_hash.delete(:série)
      student_hash.delete(:turma)
      student_hash.delete(:grade) # Garantia extra para evitar o erro específico da sua imagem

      # 4. Gravação Segura
      student = Student.find_or_initialize_by(email: email_limpo)
      
      # Filtramos o hash para garantir que só passamos colunas que existem na tabela 'students'
      valid_columns = Student.column_names.map(&:to_sym)
      student.assign_attributes(student_hash.slice(*valid_columns))
      
      unless student.save
        Rails.logger.error "Erro ao importar aluno #{student.email}: #{student.errors.full_messages.join(', ')}"
      end
    end
  end

  # --- Lógica de Desempenho e Analytics ---

  def has_user
    StudentUser.exists?(email: self.email)
  end

  def nota_na_atividade(activity_id)
    sa = self.student_activities.find_by(activity_id: activity_id)
    return 0.0 unless sa

    if sa.respond_to?(:points)
      sa.points.to_f
    elsif sa.respond_to?(:grade)
      sa.grade.to_f
    else
      sp = self.student_points.find_by(activity_id: activity_id)
      sp ? sp.points.to_f : 0.0
    end
  end

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
    lvl = self[:level] || 1 
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
    self[:level] ||= 1
    self.total_xp ||= 0

    self.total_xp += amount
    new_xp = self.xp + amount

    while new_xp >= xp_needed_for_next_level
      new_xp -= xp_needed_for_next_level
      self[:level] += 1
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

  # --- MÉTODO DE CÁLCULO DE MÉDIAS ---

  def calcular_nota_com_pesos(activity_ids)
    ids = Array(activity_ids).map(&:to_i).reject(&:zero?).uniq
    return 0.0 if ids.empty?

    atividades = Activity.where(id: ids)
    pontos_map = self.student_points.where(activity_id: ids).pluck(:activity_id, :points).to_h

    vistos = []
    listas = []
    outras_atividades = []

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

    media_vistos = vistos.any? ? (vistos.sum / vistos.size.to_f) : nil
    media_listas = listas.any? ? (listas.sum / listas.size.to_f) : nil

    total_notas_ponderadas = 0.0
    soma_pesos = 0.0

    outras_atividades.each do |item|
      total_notas_ponderadas += (item[:nota] * item[:peso])
      soma_pesos += item[:peso]
    end

    if media_vistos
      total_notas_ponderadas += media_vistos
      soma_pesos += 1.0
    end

    if media_listas
      total_notas_ponderadas += media_listas
      soma_pesos += 1.0
    end

    return 0.0 if soma_pesos.zero?
    (total_notas_ponderadas / soma_pesos).round(2)
  end

  def nota_da_prova(activity_ids)
    ponto_registro = self.student_points.joins(:activity)
                         .where(activity_id: activity_ids)
                         .where("LOWER(activities.name) LIKE ? OR LOWER(activities.name) LIKE ?", "%prova%", "%avaliação%")
                         .first

    ponto_registro ? (ponto_registro.points || 0.0) : 0.0
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
    lvl = self[:level] || 1
    case lvl
    when 1..5   then "Elétron Livre"
    when 6..10  then "Manipulador de Reações"
    when 11..15 then "Mestre da Estequiometria"
    else "Alquimista Lendário"
    end
  end

  def titles_linguagens
    lvl = self[:level] || 1
    case lvl
    when 1..5   then "Menestrel de Velastraer"
    when 6..10  then "Escriba dos Pergaminhos"
    when 11..15 then "Orador da Corte"
    else "Arquivista Real"
    end
  end

  def titles_exatas
    lvl = self[:level] || 1
    case lvl
    when 1..5   then "Calculador de Rotas"
    when 6..10  then "Geômetra do Reino"
    when 11..15 then "Engenheiro de Cerco"
    else "Arquiteto do Destino"
    end
  end

  def titles_humanas
    lvl = self[:level] || 1
    case lvl
    when 1..5   then "Explorador de Fronteiras"
    when 6..10  then "Diplomata das Nações"
    when 11..15 then "Estrategista de Guerra"
    else "Filósofo de Velastraer"
    end
  end

  def titles_geral
    lvl = self[:level] || 1
    case lvl
    when 1..5   then "Aprendiz Iniciante"
    when 6..10  then "Aventureiro"
    when 11..15 then "Herói do Conhecimento"
    else "Guardião do Maestro"
    end
  end
end