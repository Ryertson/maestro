class DashboardController < ApplicationController
  before_action :authenticate_professor!

  def index
    # 0. Identificação do Perfil Vinculado
    @teacher = current_professor.teacher || Teacher.find_by(email: current_professor.email)

    # 1. Escopo de Turmas e Disciplinas (Ajustado para o View Mode)
    if current_view_mode == :modo_admin
      @classrooms = Classroom.all
      @subjects = Subject.all
    elsif @teacher
      # Turmas onde o professor leciona
      classroom_ids = ClassroomSubject.where(teacher_id: @teacher.id).pluck(:classroom_id)
      @classrooms = Classroom.where(id: classroom_ids).distinct
      
      # Disciplinas que o professor leciona
      subject_ids = ClassroomSubject.where(teacher_id: @teacher.id).pluck(:subject_id)
      @subjects = Subject.where(id: subject_ids).distinct
    else
      @classrooms = Classroom.none
      @subjects = Subject.none
    end

    # 2. Seleção de Filtros (Turma, Disciplina e Aluno)
    @classroom = params[:classroom_id].present? ? @classrooms.find_by(id: params[:classroom_id]) : @classrooms.first
    
    if @classroom
      if current_view_mode == :modo_admin
        @subjects_in_classroom = @classroom.subjects
      else
        # Busca as disciplinas desta turma que pertencem a este professor específico
        sub_ids = ClassroomSubject.where(classroom_id: @classroom.id, teacher_id: @teacher&.id).pluck(:subject_id)
        @subjects_in_classroom = Subject.where(id: sub_ids)
      end
    else
      @subjects_in_classroom = Subject.none
    end

    # Define a disciplina ativa (Isso resolve o problema de aparecer "Inglês" se você for de Química)
    @subject = params[:subject_id].present? ? @subjects_in_classroom.find_by(id: params[:subject_id]) : @subjects_in_classroom.first

    if @classroom
      @students = @classroom.students.order(:name)
      @student = params[:student_id].present? ? @students.find_by(id: params[:student_id]) : @students.first
    end

    # Captura o período selecionado
    @period_filter = params[:period] || 'monthly'

    # 3. Dados Globais (Cards) baseados na disciplina selecionada
    if @classroom && @subject
      @atividades_recentes = Activity.where(classroom_id: @classroom.id, subject_id: @subject.id)
                                     .order(date: :desc).limit(5)
      
      notas_sistema = StudentActivity.joins(:activity)
                                     .where(activities: { subject_id: @subject.id, classroom_id: @classroom.id })
                                     .where.not(points: nil)
      
      @total_alunos = @classroom.students.count
    else
      @atividades_recentes = []
      notas_sistema = StudentActivity.none
      @total_alunos = 0
    end
    
    @media_geral = notas_sistema.any? ? notas_sistema.average(:points).to_f.round(1) : 0.0

    # 4. Lógica do Aluno e Filtros de Período (Bimestres Adicionados)
    if @student && @classroom && @subject
      @freq_semanal   = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_week)
      @freq_mensal    = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_month)
      @freq_bimestral = calcular_frequencia_isolada(@student, @subject, 2.months.ago)
      @freq_anual     = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_year)

      @media_turma_freq = calcular_media_turma_freq_isolada(@classroom, @subject, Date.today.beginning_of_month)

      # --- Lógica de Datas Dinâmica para Bimestres ---
      if params[:start_date].present? && params[:end_date].present?
        @start_date, @end_date = params[:start_date].to_date, params[:end_date].to_date
        @period_filter = 'custom'
      else
        case @period_filter
        when 'weekly'  then @start_date, @end_date = Date.today.beginning_of_week, Date.today.end_of_week
        when 'monthly' then @start_date, @end_date = Date.today.beginning_of_month, Date.today.end_of_month
        when '1b', '2b', '3b', '4b'
          # Tenta encontrar o Termo correspondente no banco (Ex: "1º Bimestre")
          map_bimestre = { '1b' => '1º', '2b' => '2º', '3b' => '3º', '4b' => '4º' }
          term = Term.find_by("name LIKE ?", "#{map_bimestre[@period_filter]}%")
          if term
            @start_date, @end_date = term.start_date, term.end_date
          else
            @start_date, @end_date = Date.today.beginning_of_year, Date.today
          end
        else
          @start_date, @end_date = Date.today.beginning_of_year, Date.today
        end
      end

      atividades_aluno = @student.student_activities.joins(:activity).where(activities: { subject_id: @subject.id })
      @total_atv = atividades_aluno.count
      @entregas_prazo   = atividades_aluno.where(status: ["Entregou", "Entregue"]).count
      @entregas_atraso  = atividades_aluno.where(status: ["Atrasado", "Entregue com Atraso"]).count
      @nao_entregues    = atividades_aluno.where(status: ["Pendente", "Não Entregou", "Não fez"]).count
      @taxa_entrega_aluno = @total_atv > 0 ? ((@entregas_prazo.to_f / @total_atv) * 100).round(0) : 0
      
      @media_aluno = atividades_aluno.where.not(points: nil).average(:points).to_f.round(1)
      @media_turma_notas = StudentActivity.joins(:student, :activity)
                                          .where(students: { classroom_id: @classroom.id }, activities: { subject_id: @subject.id })
                                          .where.not(points: nil).average(:points).to_f.round(1)

      # Gráfico de Evolução
      atividades_grafico = atividades_aluno.where.not(points: nil).where("activities.date >= ?", 6.months.ago).order("activities.date ASC")
      @labels_evolucao, @notas_aluno_evolucao, @notas_turma_evolucao = [], [], []
      
      atividades_grafico.group_by { |a| a.activity.date.strftime("%b/%y") }.each do |mes, atividades|
        @labels_evolucao << mes
        @notas_aluno_evolucao << (atividades.map(&:points).sum / atividades.size.to_f).round(1)
        
        media_t = StudentActivity.joins(:activity, :student)
                                 .where(students: { classroom_id: @classroom.id }, activities: { subject_id: @subject.id })
                                 .where("activities.date BETWEEN ? AND ?", atividades.first.activity.date.beginning_of_month, atividades.first.activity.date.end_of_month)
                                 .average(:points).to_f.round(1)
        @notas_turma_evolucao << media_t
      end
    end

    # 5. Alunos em alerta
    if @subject && @classroom
      @alunos_alerta = Student.where(classroom_id: @classroom.id)
                              .joins(student_activities: :activity)
                              .where(activities: { subject_id: @subject.id })
                              .group('students.id')
                              .select('students.*, AVG(student_activities.points) as media')
                              .having('AVG(student_activities.points) < ?', 6.0)
    else
      @alunos_alerta = []
    end
  end

  @top_alchemists = Student.order(total_xp: :desc).limit(5)

  private

  def calcular_frequencia_isolada(student, subject, data_inicio)
    # 1. Contamos quantas aulas ÚNICAS existiram
    aulas = Lesson.where(classroom_id: student.classroom_id, subject_id: subject.id)
                  .where("date >= ?", data_inicio).count
  
    return 0.0 if aulas == 0

    # 2. Mudamos de .count para .select(...).distinct.count 
    # Isso garante que se houver duplicata de presença no banco para a mesma aula, 
    # contaremos apenas 1 presença.
    presencas = Attendance.joins(:lesson)
                          .where(student_id: student.id, lessons: { subject_id: subject.id })
                          .where("lessons.date >= ?", data_inicio)
                          .where(status: ["Presente", "presente", "Atrasado", "atrasado", "Justificada", "justificada"])
                          .select(:lesson_id).distinct.count

    # 3. Calculamos o percentual e usamos o .clamp(0, 100) como trava de segurança final
    percentual = ((presencas.to_f / aulas) * 100).round(1)
    percentual.clamp(0, 100)
  end

  def calcular_media_turma_freq_isolada(classroom, subject, data_inicio)
    alunos = classroom.students
    return 0.0 if alunos.empty?
    somas = alunos.map { |s| calcular_frequencia_isolada(s, subject, data_inicio) }.sum
    (somas / alunos.count).round(1)
  end
end