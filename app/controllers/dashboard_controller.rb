class DashboardController < ApplicationController
  before_action :authenticate_professor!

  def index
    # 0. Identificação do Perfil
    @teacher = current_professor.teacher || Teacher.find_by(email: current_professor.email)

    # 1. Escopo de Turmas e Disciplinas
    if current_view_mode == :modo_admin
      @classrooms = Classroom.all
      @subjects = Subject.all
    elsif @teacher
      classroom_ids = ClassroomSubject.where(teacher_id: @teacher.id).pluck(:classroom_id)
      @classrooms = Classroom.where(id: classroom_ids).distinct
      subject_ids = ClassroomSubject.where(teacher_id: @teacher.id).pluck(:subject_id)
      @subjects = Subject.where(id: subject_ids).distinct
    else
      @classrooms = Classroom.none
      @subjects = Subject.none
    end

    # 2. Seleção de Filtros
    @classroom = params[:classroom_id].present? ? @classrooms.find_by(id: params[:classroom_id]) : @classrooms.first
    
    if @classroom
      if current_view_mode == :modo_admin
        @subjects_in_classroom = @classroom.subjects
      else
        sub_ids = ClassroomSubject.where(classroom_id: @classroom.id, teacher_id: @teacher&.id).pluck(:subject_id)
        @subjects_in_classroom = Subject.where(id: sub_ids)
      end
    else
      @subjects_in_classroom = Subject.none
    end

    @subject = params[:subject_id].present? ? @subjects_in_classroom.find_by(id: params[:subject_id]) : @subjects_in_classroom.first

    if @classroom
      @students = @classroom.students.order(:name)
      @student = params[:student_id].present? ? @students.find_by(id: params[:student_id]) : @students.first
      @ranking_turma = @classroom.students.order(total_xp: :desc).limit(3)
    end

    # 3. Lógica de Datas
    @period_filter = params[:period] || 'monthly'
    if params[:start_date].present? && params[:end_date].present?
      @start_date, @end_date = params[:start_date].to_date, params[:end_date].to_date
      @period_filter = 'custom'
    else
      case @period_filter
      when 'weekly'  then @start_date, @end_date = Date.today.beginning_of_week, Date.today.end_of_week
      when 'monthly' then @start_date, @end_date = Date.today.beginning_of_month, Date.today.end_of_month
      when '1b', '2b', '3b', '4b'
        map_bimestre = { '1b' => '1º', '2b' => '2º', '3b' => '3º', '4b' => '4º' }
        term = Term.find_by("name LIKE ?", "#{map_bimestre[@period_filter]}%")
        @start_date, @end_date = term ? [term.start_date, term.end_date] : [Date.today.beginning_of_year, Date.today]
      else
        @start_date, @end_date = Date.today.beginning_of_year, Date.today
      end
    end

    # 4. Lógica de Frequência e Atividades
    if @student && @classroom && @subject
      # Cálculos de Frequência para os cards superiores
      @freq_semanal   = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_week)
      @freq_mensal    = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_month)
      @freq_bimestral = calcular_frequencia_isolada(@student, @subject, 2.months.ago)
      @freq_anual     = calcular_frequencia_isolada(@student, @subject, Date.today.beginning_of_year)
      @media_turma_freq = calcular_media_turma_freq_isolada(@classroom, @subject, Date.today.beginning_of_month)

      # --- CONTAGEM QUANTITATIVA SINCRONIZADA COM A PÁGINA STUDENTS ---
      aulas_periodo = Lesson.where(classroom_id: @classroom.id, subject_id: @subject.id).where(date: @start_date..@end_date)
      @total_aulas_dadas = aulas_periodo.count
      
      atendimentos = Attendance.where(student_id: @student.id, lesson_id: aulas_periodo.ids)
      
      # Contagens usando os Slugs reais do banco de dados (inglês e português)
      @total_presencas    = atendimentos.where(status: ['present', 'Presente', 'presente']).count
      @total_atrasos      = atendimentos.where(status: ['late', 'Atrasado', 'atrasado']).count
      @total_justificadas = atendimentos.where(status: ['justified', 'Justificada', 'justificada']).count
      
      # Lógica de Falta: Aulas dadas - (Presenças + Atrasos + Justificativas)
      # Isso garante que no caso do Alerrandro, mostre as 4 faltas restantes.
      @total_faltas = @total_aulas_dadas - (@total_presencas + @total_atrasos + @total_justificadas)
      @total_faltas = [@total_faltas, 0].max # Evita números negativos caso haja erro de duplicidade

      # Sincronização com Atividades
      atividades_ids = @classroom.activities.where(subject_id: @subject.id).pluck(:id)
      @total_atv = atividades_ids.count
      registros_aluno = @student.student_activities.where(activity_id: atividades_ids)
      @entregas_prazo   = registros_aluno.where(status: ["Entregou", "Entregue", "No Prazo"]).count
      @entregas_atraso  = registros_aluno.where(status: ["Atrasado", "Entregue com Atraso"]).count
      @nao_entregues    = @total_atv - (@entregas_prazo + @entregas_atraso)
      @taxa_entrega_aluno = @total_atv > 0 ? (((@entregas_prazo + @entregas_atraso).to_f / @total_atv) * 100).round(0) : 0
      
      # --- NOVA LÓGICA: LINHA DO TEMPO DE ATIVIDADES ---
      # 1. Pegamos todas as atividades criadas para a turma nesta disciplina
      todas_atividades = Activity.where(classroom_id: @classroom.id, subject_id: @subject.id)
                                 .where(date: @start_date..@end_date)
                                 .order(date: :asc)

      @timeline_data = todas_atividades.map do |atv|
        # Buscamos se o aluno tem registro para esta atividade específica
        registro = @student.student_activities.find_by(activity_id: atv.id)
        
        {
          nome: atv.name.truncate(20),
          data: atv.date.strftime("%d/%m"),
          nota: registro&.points, # Pode ser nil se não fez
          fez: registro.present? && registro.points.present?
        }
      end
      
      @media_aluno = registros_aluno.where.not(points: nil).average(:points).to_f.round(1)
      @media_turma_notas = StudentActivity.joins(:student, :activity).where(students: { classroom_id: @classroom.id }, activities: { subject_id: @subject.id }).where.not(points: nil).average(:points).to_f.round(1)
    end

    @top_alchemists = Student.order(total_xp: :desc).limit(5)
  end

  private

  def calcular_frequencia_isolada(student, subject, data_inicio)
    aulas = Lesson.where(classroom_id: student.classroom_id, subject_id: subject.id).where("date >= ?", data_inicio).count
    return 0.0 if aulas == 0
    presencas = Attendance.joins(:lesson).where(student_id: student.id, lessons: { subject_id: subject.id }).where("lessons.date >= ?", data_inicio).where(status: ['present', 'Presente', 'presente', 'late', 'Atrasado', 'atrasado', 'justified', 'Justificada', 'justificada']).select(:lesson_id).distinct.count
    ((presencas.to_f / aulas) * 100).round(1).clamp(0, 100)
  end

  def calcular_media_turma_freq_isolada(classroom, subject, data_inicio)
    alunos = classroom.students
    return 0.0 if alunos.empty?
    somas = alunos.map { |s| calcular_frequencia_isolada(s, subject, data_inicio) }.sum
    (somas / alunos.count).round(1)
  end
end