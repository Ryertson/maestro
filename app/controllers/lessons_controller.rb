class LessonsController < ApplicationController
  before_action :authenticate_professor!
  before_action :set_lesson, only: %i[show edit update destroy]
  
  before_action :set_available_classrooms, only: %i[index create update prepare_index_data]
  before_action :set_available_subjects, only: %i[index create update prepare_index_data new edit]
  
  before_action :authorize_lesson_access!, only: %i[show edit update destroy]

  def index
    # 1. Iniciamos o escopo cruzando a tabela associativa de turmas
    @lessons = Lesson.left_outer_joins(:classrooms).distinct

    # 2. Se não for admin, restringe às aulas que pertencem ao professor logado
    unless current_view_mode == :modo_admin
      allowed_classroom_ids = @available_classrooms.pluck(:id)
      @lessons = @lessons.where(teacher_id: current_teacher_profile&.id)
                         .where("lessons.classroom_id IN (?) OR classrooms_lessons.classroom_id IN (?)", allowed_classroom_ids, allowed_classroom_ids)
    end

    # 3. Filtro por Turma selecionada no painel
    if params[:classroom_id].present?
      @lessons = @lessons.where("lessons.classroom_id = ? OR classrooms_lessons.classroom_id = ?", params[:classroom_id], params[:classroom_id])
    end

    # 4. Demais filtros do Maestro
    @lessons = @lessons.where(subject_id: params[:subject_id]) if params[:subject_id].present?
    
    if params[:term_id].present?
      term = Term.find_by(id: params[:term_id])
      @lessons = @lessons.where(date: term.start_date..term.end_date) if term
    end

    if params[:search].present?
      @lessons = @lessons.where("lessons.topic_name LIKE ?", "%#{params[:search]}%")
    end

    # 5. Otimização de queries N+1 e ordenação das aulas
    @lessons_list = @lessons.includes(:subject, classrooms: [:course, :level]).order(date: :desc)

    # 6. Alimenta o Dashboard e Calendário
    calculate_dashboard_data(@lessons_list)

    @terms = Term.order(:start_date)
    @academic_events = AcademicEvent.all.group_by(&:event_date)
    
    @lesson = Lesson.new
    @lesson.activities.build 
    @view_date = params[:date] ? Date.parse(params[:date]) : Date.today
    @calendar_events = build_calendar_events(@lessons_list)
  end

  def create
    # --- EXTRAÇÃO SEGURA DAS TURMAS ---
    # Captura os IDs das turmas do select múltiplo, limpando valores vazios
    selected_classroom_ids = params[:lesson][:classroom_ids]&.reject(&:blank?) || []
  
    # Caso o array venha vazio, tenta usar o ID singular para não quebrar o comportamento padrão
    if selected_classroom_ids.blank? && params[:lesson][:classroom_id].present?
      selected_classroom_ids = [params[:lesson][:classroom_id]]
    end

    # Se mesmo assim não houver turmas, barra o salvamento usando seu bloco de erro padrão
    if selected_classroom_ids.blank?
      flash.now[:alert] = "Falha ao cadastrar no Maestro. Motivo: Você precisa selecionar pelo menos uma turma."
      prepare_index_data
      return respond_to do |format|
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: { errors: ["Classroom can't be blank"] }, status: :unprocessable_entity }
      end
    end

    # Isolamos os parâmetros base da aula para podermos instanciar uma por turma
    base_params = lesson_params.except(:classroom_ids)
  
    # Inicializamos as variáveis de controle que seu código já utiliza
    attendance_errors = []
    lesson_save_failed = false
    @lesson = nil # Será usada para reter a última instância ou alimentar a view em caso de falha

    # --- O LOOP DE MULTIPLICAÇÃO ---
    selected_classroom_ids.each do |classroom_id|
      classroom = Classroom.find_by(id: classroom_id)
      next unless classroom

      # Criamos uma aula física nova para cada turma selecionada no laço
      current_lesson = Lesson.new(base_params)
      current_lesson.teacher_id = current_teacher_profile&.id
      current_lesson.classroom_id = classroom_id

      # Se houver atividade vinculada, duplicamos os atributos aninhados injetando a turma atual
      if current_lesson.has_activity && params[:lesson][:activities_attributes].present?
        params[:lesson][:activities_attributes].each do |_index, act_params|
          current_lesson.activities.build(act_params.merge(classroom_id: classroom_id))
        end
      end

      if current_lesson.save
        @lesson = current_lesson # Guarda uma instância válida para o respond_to de sucesso

        # Executa exatamente a sua lógica de frequências (chamada) para a turma da vez
        classroom.students.each do |student|
          attendance = current_lesson.attendances.find_or_initialize_by(student_id: student.id)
          attendance.classroom_id = classroom_id
          attendance.status       = "Presente" if attendance.new_record? 

          unless attendance.save
            attendance_errors << "#{student.name}: #{attendance.errors.full_messages.join(', ')}"
          end
        end
      else
        @lesson = current_lesson # Retém a instância com os erros de validação para exibir na tela
        lesson_save_failed = true
        break # Interrompe o processo se uma das turmas falhar na validação interna
      end
    end

    # --- SEUS RESPOND_TO E TRATAMENTOS DE FLUSH MANANTIDOS ---
    respond_to do |format|
      unless lesson_save_failed
        if attendance_errors.any?
          flash[:warning] = "Aula criada, mas houve problemas nas frequências: #{attendance_errors.first(3).join(' | ')}"
        else
          flash[:notice] = "Aula cadastrada com sucesso nas turmas selecionadas!"
        end

        format.html { redirect_to lessons_path }
        format.json { render :show, status: :created, location: @lesson }
      else
        # Se falhou, reconstrói os dados usando o seu padrão exato de tratamento
        error_messages = @lesson.errors.full_messages.join(", ")
        flash.now[:alert] = "Falha ao cadastrar no Maestro. Motivo: #{error_messages}"
        prepare_index_data
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    unless can_manage_lesson?(@lesson)
      redirect_to lessons_path, alert: "Você não tem permissão para editar esta aula."
      return
    end

    current_params = lesson_params
    if params[:lesson][:has_activity] == "0"
      current_params.delete(:activities_attributes)
    end

    @lesson.assign_attributes(current_params)
    
    # --- AJUSTE CRUCIAL: Garante o professor também no update ---
    @lesson.teacher_id ||= current_teacher_profile&.id

    if @lesson.save
      redirect_to lessons_path, notice: "Aula atualizada com sucesso!"
    else
      @lesson.activities.build if @lesson.activities.empty?
      prepare_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    unless can_manage_lesson?(@lesson)
      redirect_to lessons_path, alert: "Você não tem permissão para excluir esta aula."
      return
    end

    if @lesson.destroy
      redirect_to lessons_path, notice: "Tópico excluído permanentemente."
    else
      redirect_to lessons_path, alert: "Erro ao excluir: #{@lesson.errors.full_messages.to_sentence}"
    end
  end

  def prepare_index_data
    @lessons = Lesson.left_outer_joins(:classrooms).distinct

    unless current_view_mode == :modo_admin
      allowed_classroom_ids = @available_classrooms.pluck(:id)
      @lessons = @lessons.where(teacher_id: current_teacher_profile&.id)
                         .where("lessons.classroom_id IN (?) OR classrooms_lessons.classroom_id IN (?)", allowed_classroom_ids, allowed_classroom_ids)
    end
    
    if params[:classroom_id].present?
      @lessons = @lessons.where("lessons.classroom_id = ? OR classrooms_lessons.classroom_id = ?", params[:classroom_id], params[:classroom_id])
    end
    
    @lessons = @lessons.where(subject_id: params[:subject_id]) if params[:subject_id].present?
    
    if params[:term_id].present?
      term = Term.find_by(id: params[:term_id])
      @lessons = @lessons.where(date: term.start_date..term.end_date) if term
    end
    
    @lessons_list = @lessons.includes(:subject, classrooms: [:course, :level]).order(date: :desc)
    calculate_dashboard_data(@lessons_list)
    
    @terms = Term.order(:start_date)
    @calendar_events = build_calendar_events(@lessons_list)
    
    @lesson ||= Lesson.new
    @lesson.activities.build if @lesson.activities.empty?
  end

  private

  def can_manage_lesson?(lesson)
    return true if current_view_mode == :modo_admin
    return true if lesson.teacher_id == current_teacher_profile&.id
    false
  end
  helper_method :can_manage_lesson?

  def current_teacher_profile
    @current_teacher_profile ||= current_professor.teacher || Teacher.find_by(email: current_professor.email)
  end
  helper_method :current_teacher_profile

  def set_available_classrooms
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
    unless allowed_ids.include?(@lesson.classroom_id) || (@lesson.classroom_ids & allowed_ids).any?
      redirect_to lessons_path, alert: "Você não tem permissão para acessar esta aula."
    end
  end

  def calculate_dashboard_data(lessons_scope)
    if lessons_scope.respond_to?(:where)
      # Limpa ordenações conflitantes e garante contagem única no Postgres
      base_scope = lessons_scope.unscope(:order)
    
      @total_lessons = base_scope.distinct.count(:id)
      @lessons_ready = base_scope.where(status: "pronto").distinct.count
      @lessons_in_progress = base_scope.where(status: "preparando").distinct.count
      @lessons_not_started = base_scope.where(status: "não_iniciada").distinct.count
      lesson_ids = base_scope.pluck(:id)
    else
      # Fallback caso receba um Array comum de dados
      @total_lessons = lessons_scope.size
      @lessons_ready = lessons_scope.select { |l| l.status == "pronto" }.size
      @lessons_in_progress = lessons_scope.select { |l| l.status == "preparando" }.size
      @lessons_not_started = lessons_scope.select { |l| l.status == "não_iniciada" }.size
      lesson_ids = lessons_scope.map(&:id)
    end

    @progress_percentage = @total_lessons > 0 ? ((@lessons_ready.to_f / @total_lessons) * 100).round : 0

    # Dashboard de entregas de atividades relacionados às aulas filtradas
    @filtered_activities = Activity.where(lesson_id: lesson_ids)
    @entregas_no_prazo   = @filtered_activities.where(status: "entregue_no_prazo").count
    @entregas_em_atraso  = @filtered_activities.where(status: "entregue_com_atraso").count
    @entregas_pendentes  = @filtered_activities.where(status: "pendente").count
    @entregas_corrigidas = @filtered_activities.where(status: "corrigida").count
  end

  def set_lesson
    @lesson = Lesson.find(params[:id])
  end

  def lesson_params
    params.require(:lesson).permit(
      :topic_name, 
      :subject_id, 
      :date, 
      :status, 
      :has_activity, 
      :classroom_id,       
      classroom_ids: [], # <--- ESSA LINHA É CRUCIAL PERMANECER ASSIM
      activities_attributes: [:id, :name, :activity_type, :points, :date, :classroom_id, :subject_id, :status]
    )
  end

  def build_calendar_events(lessons_source)
    events = {}
    lessons_source.each do |l|
      next unless l.date
      events[l.date] ||= []
      events[l.date] << { id: l.id, name: l.topic_name, type: 'lesson', status: l.status }
    end
    events
  end
end