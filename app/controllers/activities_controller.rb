class ActivitiesController < ApplicationController
  before_action :authenticate_professor!
  before_action :set_teacher_context
  before_action :set_available_classrooms
  before_action :set_activity, only: %i[ show edit update destroy mark_as_corrected ]
  # Proteção contra acesso direto via ID na URL
  before_action :authorize_activity_access!, only: %i[ show edit update destroy mark_as_corrected ]

  def index
    prepare_index_data
    @activity = Activity.new

      # Adicione esta lógica para carregar todas as atividades (usada na aba de corrigidas)
    if current_professor.admin?
      @all_activities = Activity.all
    else
      # Busca o perfil do professor para filtrar as atividades das turmas dele
      teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)
      @all_activities = Activity.where(classroom_id: Classroom.joins(:classroom_subjects)
                                .where(classroom_subjects: { teacher_id: teacher_profile.id }).pluck(:id))
    end
  end

  def create
    @activity = Activity.new(activity_params)
  
    # Força o status inicial caso não venha do form
    @activity.status ||= "pendente" 

    if @activity.save
      redirect_to activities_path(current_activity_id: @activity.id), notice: "Atividade criada e vinculada!"
    else
      prepare_index_data
      render :index, status: :unprocessable_entity
    end
  end

  # Salva as notas e os status de entrega (Verde/Amarelo/Vermelho)
  def save_submissions
    student_points_params = params[:student_points]
    statuses = params[:statuses]
    activity_id = params[:current_activity_id]

    if student_points_params.blank?
      return redirect_back(fallback_location: activities_path, alert: "Nenhuma nota foi recebida.")
    end

    @active_activity = Activity.find(activity_id)

    # Segurança: Impede salvar notas de atividade que não pertence ao professor
    unless current_professor.admin? || @available_classrooms.pluck(:id).include?(@active_activity.classroom_id)
      return redirect_to activities_path, alert: "Acesso negado."
    end

    student_points_params.each do |student_id, value|
      # 1. Salva na tabela de Auditoria/Entrega (StudentActivity)
      submission = StudentActivity.find_or_initialize_by(
        student_id: student_id, 
        activity_id: activity_id
      )
      submission.points = value.to_f
      submission.status = statuses[student_id] if statuses
      submission.save

      # 2. SALVA NA TABELA DO MAPA DE PONTOS (StudentPoint)
      point_record = StudentPoint.find_or_initialize_by(
        student_id: student_id,
        activity_id: activity_id
      )
      point_record.points = value.to_f
      point_record.save
    end

    redirect_to activities_path(current_activity_id: activity_id), notice: "Notas integradas ao Mapa de Pontos com sucesso!"
  end

  def mark_as_corrected
    @activity = Activity.find(params[:id])
  
    # 1. Atualiza os status dos alunos de "Pendente" para "Não Entregue"
    @activity.student_activities.where(status: "Pendente").update_all(status: "Não Entregue")

    # 2. Tenta atualizar o status da atividade e redireciona APENAS UMA VEZ
    if @activity.update(status: "corrigida")
      # O uso do 'return' garante que o código pare aqui
      redirect_to activities_path, notice: "Atividade finalizada e pendências atualizadas!"
    else
      redirect_to activities_path, alert: "Não foi possível finalizar a atividade."
    end
  end

  def update
    if @activity.update(activity_params)
      redirect_to activities_path(current_activity_id: @activity.id), notice: "Atividade atualizada com sucesso."
    else
      prepare_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy
    redirect_to activities_path, notice: "Atividade excluída permanentemente."
  end

  private

  def prepare_index_data
    # Escopo de IDs permitidos (para os filtros de banco de dados)
    allowed_ids = @available_classrooms.pluck(:id)

    # Prioridade 1: Atividade clicada pelo usuário
    if params[:current_activity_id].present?
      @active_activity = Activity.where(classroom_id: allowed_ids).find_by(id: params[:current_activity_id])
    end

    # Prioridade 2: Se não houver clique, pega a última pendente das turmas do professor
    if @active_activity.nil?
      @active_activity = Activity.where(classroom_id: allowed_ids)
                                 .where.not(status: "corrigida")
                                 .order(created_at: :desc).first
    end

    # Prioridade 3: Pega a última do histórico
    if @active_activity.nil?
      @active_activity = Activity.where(classroom_id: allowed_ids).last
    end

    # Dados da Atividade Ativa
    if @active_activity
      @students = @active_activity.classroom.students.order(:name)
      @active_student_activities = @active_activity.student_activities.index_by(&:student_id)
    else
      @students = []
      @active_student_activities = {}
    end

    # Listas para as Abas (Tabs) - Filtradas pelo vínculo
    @pending_activities = Activity.where(classroom_id: allowed_ids)
                                   .where.not(status: "corrigida")
                                   .order(date: :asc)

    @history_activities = Activity.where(classroom_id: allowed_ids)
                                   .where(status: "corrigida")
                                   .order(date: :desc)
                                   .limit(10)

    # Lista de aulas para o formulário (Filtrada)
    @lessons_for_select = Lesson.where(classroom_id: allowed_ids).order(date: :desc)
  end

  def set_teacher_context
    @teacher = current_professor.teacher
  end

  def set_available_classrooms
    if current_professor.admin?
      @available_classrooms = Classroom.all
    elsif @teacher
      @available_classrooms = Classroom.joins(:classroom_subjects)
                                       .where(classroom_subjects: { teacher_id: @teacher.id })
                                       .distinct
    else
      @available_classrooms = Classroom.none
    end
  end

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def authorize_activity_access!
    return if current_professor.admin?
    
    unless @available_classrooms.pluck(:id).include?(@activity.classroom_id)
      redirect_to activities_path, alert: "Você não tem permissão para gerenciar esta atividade."
    end
  end

  def activity_params
    params.require(:activity).permit(
      :name, :points, :date, :activity_type, :lesson_id, :classroom_id, 
      :status, :subject_id, :student_delivery_date, :teacher_delivery_date, :grade
    )
  end

  def update_status
    # Buscamos a StudentActivity (a entrega do aluno)
    @student_activity = StudentActivity.find(params[:student_activity_id])
    @activity = @student_activity.activity # Garante que temos a atividade pai
  
    new_status = params[:new_status]

    if @student_activity.update(status: new_status)
      # Lógica de data automática
      if new_status == 'Entregue' && @student_activity.delivered_at.nil?
        @student_activity.update(delivered_at: Date.today)
      elsif new_status == 'Pendente' || new_status == 'Não Entregue'
        @student_activity.update(delivered_at: nil)
      end

      # IMPORTANTE: Redireciona de volta para a atividade ativa com o parâmetro correto
      redirect_to activities_path(current_activity_id: @activity.id), notice: "Status de #{@student_activity.student.name} atualizado!"
    else
      redirect_to activities_path(current_activity_id: @activity.id), alert: "Erro ao atualizar status."
    end
  end
end