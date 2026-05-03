module StudentPortal
  class DashboardsController < ApplicationController
    # --- AJUSTE DE SEGURANÇA MAESTRO ---
    # 1. Pulamos a exigência global de professor para permitir a entrada do Aluno
    skip_before_action :authenticate_professor!
    
    # 2. Criamos uma trava flexível: Exige login de Aluno OU de Professor
    before_action :autenticar_acesso_portal

    def index
      # --- IDENTIFICAÇÃO DO ALUNO (Lógica Inteligente) ---
      # Se houver um aluno logado, usamos o perfil dele.
      # Se for um professor logado (você testando), usamos o ID do parâmetro ou o primeiro do banco.
      if student_user_signed_in?
        @student = current_student_user.student
      elsif professor_signed_in?
        @student = Student.find_by(id: params[:student_id]) || Student.first
      end

      if @student.nil?
        # Redireciona conforme o tipo de usuário logado
        path = professor_signed_in? ? root_path : new_student_user_session_path
        redirect_to path, alert: "Perfil de aluno não localizado no sistema." and return
      end

      @classroom = @student.classroom
      @subjects = @classroom&.subjects || []

      # Filtro de Disciplina (Geral ou Específica)
      if params[:subject_id].present? && params[:subject_id] != "geral"
        @subject = @subjects.find_by(id: params[:subject_id])
        scope_subjects_ids = @subject ? [@subject.id] : @subjects.pluck(:id)
      else
        @subject = nil
        scope_subjects_ids = @subjects.pluck(:id)
      end

      # Filtro de Período
      @period_filter = params[:period] || '1b'
      configurar_periodo

      # --- CÁLCULOS DE FREQUÊNCIA (Cards Neon) ---
      @freq_semanal   = calcular_frequencia_portal(@student, scope_subjects_ids, Date.today.beginning_of_week)
      @freq_mensal    = calcular_frequencia_portal(@student, scope_subjects_ids, Date.today.beginning_of_month)
      @freq_bimestral = calcular_frequencia_portal(@student, scope_subjects_ids, 2.months.ago)
      @freq_anual     = calcular_frequencia_portal(@student, scope_subjects_ids, Date.today.beginning_of_year)

      # --- DADOS QUANTITATIVOS ---
      aulas_ids = Lesson.where(classroom_id: @classroom.id, subject_id: scope_subjects_ids)
                        .where(date: @start_date..@end_date).pluck(:id)
      
      @total_aulas_dadas = aulas_ids.count
      atendimentos = Attendance.where(student_id: @student.id, lesson_id: aulas_ids)

      @total_presencas    = atendimentos.where(status: ['present', 'Presente', 'presente']).count
      @total_atrasos      = atendimentos.where(status: ['late', 'Atrasado', 'atrasado']).count
      @total_justificadas = atendimentos.where(status: ['justified', 'Justificada', 'justificada']).count
      @total_faltas       = [(@total_aulas_dadas - (@total_presencas + @total_atrasos + @total_justificadas)), 0].max

      # --- STATUS DE ENTREGA ---
      atividades_ids = Activity.where(classroom_id: @classroom.id, subject_id: scope_subjects_ids).pluck(:id)
      registros_atividades = @student.student_activities.where(activity_id: atividades_ids)
      
      @total_atv        = atividades_ids.count
      @entregas_prazo   = registros_atividades.where(status: ["Entregou", "Entregue", "No Prazo"]).count
      @entregas_atraso  = registros_atividades.where(status: ["Atrasado", "Entregue com Atraso"]).count
      @nao_entregues    = [@total_atv - (@entregas_prazo + @entregas_atraso), 0].max
      @taxa_entrega     = @total_atv > 0 ? ((@entregas_prazo + @entregas_atraso).to_f / @total_atv * 100).round(0) : 0

      # --- LINHA DO TEMPO ---
      atividades_scope = @subject ? Activity.where(subject_id: @subject.id) : Activity.where(subject_id: scope_subjects_ids)
      @timeline_data = atividades_scope.where(classroom_id: @classroom.id).where(date: @start_date..@end_date).order(date: :asc).map do |atv|
        reg = @student.student_activities.find_by(activity_id: atv.id)
        { nome: atv.name.truncate(15), data: atv.date.strftime("%d/%m"), nota: reg&.points, fez: reg&.points.present? }
      end

      # --- MÉDIAS E RANKING ---
      @media_aluno = registros_atividades.where.not(points: nil).average(:points).to_f.round(1)
      @ranking_turma = @classroom.students.order(total_xp: :desc).limit(3)
    end

    private

    def autenticar_acesso_portal
      # Se não houver nem Aluno nem Professor logado, manda para o login de Aluno
      unless student_user_signed_in? || professor_signed_in?
        redirect_to new_student_user_session_path, alert: "Você precisa entrar no sistema para acessar o portal."
      end
    end

    def configurar_periodo
      if params[:start_date].present? && params[:end_date].present?
        @start_date, @end_date = params[:start_date].to_date, params[:end_date].to_date
      else
        case @period_filter
        when 'weekly'  then @start_date, @end_date = Date.today.beginning_of_week, Date.today.end_of_week
        when 'monthly' then @start_date, @end_date = Date.today.beginning_of_month, Date.today.end_of_month
        when '1b', '2b', '3b', '4b'
          term = Term.find_by("name LIKE ?", "#{ @period_filter[0] }º%")
          @start_date, @end_date = term ? [term.start_date, term.end_date] : [Date.today.beginning_of_year, Date.today]
        else
          @start_date, @end_date = Date.today.beginning_of_year, Date.today
        end
      end
    end

    def calcular_frequencia_portal(student, subject_ids, data_inicio)
      total = Lesson.where(classroom_id: student.classroom_id, subject_id: subject_ids).where("date >= ?", data_inicio).count
      return 0.0 if total == 0
      pres = Attendance.joins(:lesson).where(student_id: student.id, lessons: { subject_id: subject_ids }).where("lessons.date >= ?", data_inicio)
                       .where(status: ['present', 'Presente', 'presente', 'late', 'Atrasado', 'atrasado', 'justified', 'Justificada', 'justificada']).count
      ((pres.to_f / total) * 100).round(1)
    end
  end
end