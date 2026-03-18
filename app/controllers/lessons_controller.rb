class LessonsController < ApplicationController
  before_action :authenticate_professor!
  before_action :set_lesson, only: %i[show edit update destroy]
  
  # Carrega as turmas e disciplinas permitidas baseando-se no current_view_mode
  before_action :set_available_classrooms, only: %i[index create update prepare_index_data]
  before_action :set_available_subjects, only: %i[index create update prepare_index_data new edit]
  
  # Proteção de acesso via ID na URL
  before_action :authorize_lesson_access!, only: %i[show edit update destroy]

  def index
    # 1. Escopo de busca ajustado para o View Mode
    @base_lessons = if current_view_mode == :modo_admin
                      Lesson.all
                    else
                      # Se for Modo Professor (mesmo sendo Admin logado), filtra pelo perfil de Teacher
                      Lesson.where(teacher_id: current_teacher_profile&.id)
                            .where(classroom_id: @available_classrooms.pluck(:id))
                    end

    # 2. Aplicação de Filtros (Classroom, Subject e Search)
    @lessons = @base_lessons
    @lessons = @lessons.where(classroom_id: params[:classroom_id]) if params[:classroom_id].present?
    @lessons = @lessons.where(subject_id: params[:subject_id]) if params[:subject_id].present?
    
    if params[:search].present?
      @lessons = @lessons.where("topic_name LIKE ?", "%#{params[:search]}%")
    end

    # 3. Dados para os CARDS e Dashboard (Seguem o escopo filtrado acima)
    calculate_dashboard_data(@lessons)

    # 4. BIMESTRES e Ordenação para a Tabela
    @terms = Term.order(:start_date)
    @lessons_list = @lessons.includes(:subject, classroom: [:course, :grade]).order(date: :desc)
    
    # 5. Variáveis para o Formulário de Cadastro Rápido e Calendário
    @lesson = Lesson.new
    @lesson.activities.build 
    @view_date = params[:date] ? Date.parse(params[:date]) : Date.today
    @calendar_events = build_calendar_events(@lessons)
  end

  def create
    current_params = lesson_params
    if params[:lesson][:has_activity] == "0"
      current_params.delete(:activities_attributes)
    end

    @lesson = Lesson.new(current_params)
    
    # Vincula o ID do professor logado se estivermos no modo professor
    if current_view_mode == :modo_professor
      @lesson.teacher_id = current_teacher_profile&.id
    end

    respond_to do |format|
      if @lesson.save
        format.html { redirect_to lessons_path, notice: "Aula cadastrada com sucesso!" }
        format.turbo_stream
      else
        prepare_index_data 
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def update
    current_params = lesson_params
    if params[:lesson][:has_activity] == "0"
      current_params.delete(:activities_attributes)
    end

    if @lesson.update(current_params)
      redirect_to lessons_path, notice: "Aula atualizada com sucesso!"
    else
      prepare_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    if @lesson.destroy
      redirect_to lessons_path, notice: "Tópico excluído permanentemente."
    else
      redirect_to lessons_path, alert: "Erro ao excluir: #{@lesson.errors.full_messages.to_sentence}"
    end
  end

  def update_term
    @term = Term.find(params[:id])
    if @term.update(term_params)
      render json: { success: true }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def prepare_index_data
    @base_lessons = if current_view_mode == :modo_admin
                      Lesson.all
                    else
                      Lesson.where(teacher_id: current_teacher_profile&.id)
                            .where(classroom_id: @available_classrooms.pluck(:id))
                    end
    @lessons = @base_lessons
    @lessons_list = @lessons.includes(:subject, classroom: [:course, :grade]).order(date: :desc)
    @terms = Term.order(:start_date)
    @calendar_events = build_calendar_events(@lessons)
    calculate_dashboard_data(@lessons)
    @lesson ||= Lesson.new
  end

  private

  # Centraliza a lógica do perfil do professor
  def current_teacher_profile
    @current_teacher_profile ||= current_professor.teacher || Teacher.find_by(email: current_professor.email)
  end
  helper_method :current_teacher_profile

  def set_available_classrooms
    # Se for Admin e estiver no Modo Admin, vê tudo. Caso contrário, vê apenas as suas turmas.
    if current_view_mode == :modo_admin
      @available_classrooms = Classroom.all
    elsif current_teacher_profile
      @available_classrooms = Classroom.joins(:classroom_subjects)
                                       .where(classroom_subjects: { teacher_id: current_teacher_profile.id })
                                       .distinct
    else
      @available_classrooms = Classroom.none
    end
  end

  def set_available_subjects
    if current_view_mode == :modo_admin
      @available_subjects = Subject.all
    elsif current_teacher_profile
      subject_ids = ClassroomSubject.where(teacher_id: current_teacher_profile.id).pluck(:subject_id)
      @available_subjects = Subject.where(id: subject_ids).distinct
    else
      @available_subjects = Subject.none
    end
  end

  def authorize_lesson_access!
    return if current_view_mode == :modo_admin
    
    allowed_ids = Classroom.joins(:classroom_subjects)
                           .where(classroom_subjects: { teacher_id: current_teacher_profile&.id })
                           .pluck(:id)
    
    unless allowed_ids.include?(@lesson.classroom_id)
      redirect_to lessons_path, alert: "Você não tem permissão para acessar esta aula."
    end
  end

  def calculate_dashboard_data(scope)
    @total_lessons = scope.count
    @lessons_ready = scope.where(status: "pronto").count
    @lessons_in_progress = scope.where(status: "preparando").count
    @lessons_not_started = scope.where(status: "não_iniciada").count
    @progress_percentage = @total_lessons > 0 ? ((@lessons_ready.to_f / @total_lessons) * 100).round : 0
  end

  def set_lesson
    @lesson = Lesson.find(params[:id])
  end

  def lesson_params
    params.require(:lesson).permit(
      :topic_name, :date, :week, :status, :classroom_id, :subject_id, :has_activity, :teacher_id,
      activities_attributes: [
        :id, :name, :activity_type, :points, :status, :date, :classroom_id, :subject_id, :_destroy
      ]
    )
  end

  def term_params
    params.require(:term).permit(:start_date, :end_date, :color)
  end

  def build_calendar_events(lessons)
    events = {}
    lessons.each do |l|
      next unless l.date
      events[l.date] ||= []
      events[l.date] << { 
        id: l.id, 
        name: l.topic_name, 
        type: 'lesson',
        status: l.status 
      }
    end
    events
  end
end