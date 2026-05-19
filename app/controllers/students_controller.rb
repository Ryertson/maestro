require 'csv'

class StudentsController < ApplicationController
  # 1. Primeiro declaramos as proteções padrão do sistema
  before_action :authenticate_professor!, unless: -> { request.format.json? }
  before_action :set_student, only: %i[ show edit update destroy ]
  before_action :set_teacher_context, unless: -> { request.format.json? }
  
  # 2. Pulamos TODAS as travas e validações quando a requisição for JSON (Portal do Aluno)
  skip_before_action :authenticate_professor!, only: [:index], if: -> { request.format.json? }, raise: false
  skip_before_action :verify_authenticity_token, only: [:index], if: -> { request.format.json? }, raise: false

  # Trava de segurança para impedir acesso via ID na URL - Ignorada completamente se for JSON
  before_action :authorize_student_access!, only: %i[ show edit update destroy ], unless: -> { request.format.json? }

  def index
    # Capturamos o classroom_id logo no início para ser usado por ambos os formatos
    @classroom_id = params[:classroom_id] || session[:last_classroom_id]

    respond_to do |format|
      # --- FORMATO HTML (Visão do Professor) ---
      format.html do
        @selected_date = params[:month_year].present? ? Date.parse("#{params[:month_year]}-01") : Date.today
        @start_of_month = @selected_date.beginning_of_month
        @end_of_month = @selected_date.end_of_month

        if current_professor&.admin?
          @available_classrooms = Classroom.all
        elsif @teacher
          @available_classrooms = Classroom.joins(:classroom_subjects)
                                           .where(classroom_subjects: { teacher_id: @teacher.id })
                                           .distinct
        else
          @available_classrooms = Classroom.none
        end

        unless current_professor&.admin? || @available_classrooms.pluck(:id).include?(@classroom_id.to_i)
          @classroom_id = @available_classrooms.first&.id
        end
        session[:last_classroom_id] = @classroom_id if @classroom_id.present?

        if @classroom_id.present?
          @classroom = Classroom.find(@classroom_id)
          @students = @classroom.students.includes(:attendances).order(:name)
          @students = @students.where(id: params[:student_id]) if params[:student_id].present?
          @lessons_in_month = Lesson.where(classroom_id: @classroom_id, date: @start_of_month..@end_of_month)
          @planned_dates = @lessons_in_month.pluck(:date).to_set
          
          relevant_attendances = Attendance.where(classroom_id: @classroom_id, date: @start_of_month..@end_of_month)
          @total_presents   = relevant_attendances.where(status: ['Presente', 'present']).count
          @total_absents     = relevant_attendances.where(status: ['Faltou', 'absent', 'Absent']).count
          @total_lates       = relevant_attendances.where(status: ['Atrasado', 'late', 'Late']).count
          @total_justified   = relevant_attendances.where(status: ['Justificada', 'justified', 'Justified']).count

          total_possible_slots = @students.count * @planned_dates.size
          @attendance_rate = total_possible_slots > 0 ? (((@total_presents + @total_lates + @total_justified).to_f / total_possible_slots) * 100).round(1) : 0
        else
          @students = Student.none
          @planned_dates = Set.new
          @attendance_rate = 0
        end
      end

      # --- FORMATO JSON (Portal do Aluno - CORRIGIDO E BLINDADO) ---
      format.json do
        if params[:classroom_id].present?
          # Coleta os IDs dos alunos que já criaram conta para excluí-los da busca
          ids_cadastrados = StudentUser.where.not(student_id: nil).pluck(:student_id)
          
          # Busca os alunos disponíveis usando uma query limpa e direta
          @json_students = Student.where(classroom_id: params[:classroom_id])
          @json_students = @json_students.where.not(id: ids_cadastrados) if ids_cadastrados.any?
          @json_students = @json_students.order(:name)
          
          render json: @json_students.as_json(only: [:id, :name])
        else
          render json: []
        end
      end
    end
  end

  def busca_portal
    if params[:classroom_id].present?
      ids_cadastrados = StudentUser.where.not(student_id: nil).pluck(:student_id)
      
      @alunos = Student.where(classroom_id: params[:classroom_id])
      @alunos = @alunos.where.not(id: ids_cadastrados) if ids_cadastrados.any?
      @alunos = @alunos.order(:name)
      
      render json: @alunos.as_json(only: [:id, :name])
    else
      render json: []
    end
  end

  def show
    @student = Student.find(params[:id])
    @classroom = @student.classroom

    # 1. Carrega todas as disciplinas da turma para listar as tags na View
    @subjects = @classroom.subjects.distinct
  
    # 2. Captura os filtros selecionados pelo professor na tela
    @selected_subject_id = params[:subject_id].presence
    @selected_period = params[:period].presence || "1º Bimestre"

    # 3. Base original de atividades da turma
    atividades_da_turma = @classroom.activities.order(date: :asc)

    # 4. Aplica o filtro de Disciplina na contagem se o professor tiver selecionado uma tag
    if @selected_subject_id
      atividades_da_turma = atividades_da_turma.where(subject_id: @selected_subject_id)
    end

    # 5. Mapeia os meses do período selecionado para filtrar o Status de Entrega e a Média
    meses_do_periodo = case @selected_period
                      when "1º Bimestre" then [2, 3, 4]
                      when "2º Bimestre" then [5, 6, 7]
                      when "3º Bimestre" then [8, 9, 10]
                      when "4º Bimestre" then [11, 12, 1]
                      else []
                      end

    if meses_do_periodo.any?
      atividades_filtradas_por_periodo = atividades_da_turma.joins(:lesson)
                                                            .where(lessons: { classroom_id: @classroom.id })
                                                            .where(date: Date.new(Date.today.year, 2, 1)..Date.new(Date.today.year, 4, 30))
                                                            .order(date: :asc)
    else
      atividades_filtradas_por_periodo = atividades_da_turma
    end

    relevant_activity_ids = atividades_filtradas_por_periodo.pluck(:id)

    # 2. Agrupamento por Bimestres (Mês) para a tabela visual
    @activities_by_bimester = atividades_da_turma.group_by do |activity|
      month = activity.date&.month || 0
      case month
      when 2..4  then "1º Bimestre"
      when 5..7  then "2º Bimestre"
      when 8..10 then "3º Bimestre"
      when 11, 12, 1 then "4º Bimestre"
      else "Atividades Extra-Bimestrais"
      end
    end

    @submissions = @student.student_activities.where(activity_id: relevant_activity_ids).index_by(&:activity_id)

    @media_final = @student.calcular_nota_com_pesos(relevant_activity_ids)

    @total_aulas = Lesson.where(classroom_id: @classroom.id).count
    presencas_count = Attendance.where(student_id: @student.id)
                                .where(status: ['Presente', 'present', 'Atrasado', 'late', 'Justificada', 'justified'])
                                .count
    @faltas_count = @total_aulas - presencas_count
    @percentual_presenca = @total_aulas > 0 ? ((presencas_count.to_f / @total_aulas) * 100).round(1) : 0
    @percentual_faltas = (100 - @percentual_presenca).round(1)

    @no_prazo_count = @submissions.values.count { |s| s.status == 'Entregue' }
    @atraso_count   = @submissions.values.count { |s| s.status == 'Entregue com Atraso' }
  
    total_atividades_contexto = relevant_activity_ids.count
    total_entregues_contexto = @submissions.values.count { |s| ['Entregue', 'Entregue com Atraso'].include?(s.status) }
    @pendente_count = [total_atividades_contexto - total_entregues_contexto, 0].max
  end

  def edit; end

  def update
    if @student.update(student_params)
      redirect_to classroom_path(@student.classroom), notice: "Informações do aluno atualizadas."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    classroom = @student.classroom
    @student.destroy
    redirect_to classroom_path(classroom), notice: "Aluno removido com sucesso.", status: :see_other
  end

  def download_template
    csv_data = CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << ["NOME DO ALUNO", "EMAIL", "CURSO", "SÉRIE", "TURMA"]
      csv << ["JOÃO SILVA", "joao@escola.com", "Agroecologia", "1ª Série", "A"]
    end
    send_data csv_data, filename: "modelo_maestro_importacao.csv", type: "text/csv"
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def set_teacher_context
    @teacher = current_professor&.teacher
  end

  def authorize_student_access!
    return if current_professor&.admin?
    
    allowed_classroom_ids = Classroom.joins(:classroom_subjects)
                                     .where(classroom_subjects: { teacher_id: @teacher&.id })
                                     .pluck(:id)
    
    unless allowed_classroom_ids.include?(@student.classroom_id)
      redirect_to students_path, alert: "Acesso negado: Este aluno pertence a uma turma fora do seu vínculo."
    end
  end

  def student_params
    params.require(:student).permit(:name, :email, :course, :grade, :section, :active, :classroom_id, :level_id)
  end
end