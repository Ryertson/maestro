class TeachersController < ApplicationController
  before_action :authenticate_professor! # Exige login para qualquer ação
  skip_before_action :authenticate_professor!, only: [:new, :create]
  before_action :set_teacher, only: [:show, :edit, :update, :destroy, :link_login, :unlink_login]

  def index
    # Carrega professores com suas turmas, disciplinas e o login (professor) vinculado
    @teachers = Teacher.includes(:classrooms, :subjects, :professor).all
  end

  def show
  end

  def new
    @teacher = Teacher.new
  end

  def edit
  end

  def create
    @teacher = Teacher.new(teacher_params)
    if @teacher.save
      redirect_to @teacher, notice: "Professor criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 1. Capturamos os IDs das disciplinas vindos do formulário (se houver)
    subject_ids = params[:teacher][:subject_ids].reject(&:blank?) if params.dig(:teacher, :subject_ids)

    # 2. Atualizamos os dados básicos
    # Usamos o slice/except para evitar que subject_ids cause erro no update direto do objeto Teacher
    if @teacher.update(teacher_params.except(:subject_ids))
      
      # 3. Atualização manual das Atribuições (Subjects)
      if subject_ids
        @teacher.teacher_assignments.destroy_all # Limpa para evitar duplicados
        subject_ids.each do |s_id|
          @teacher.teacher_assignments.create(subject_id: s_id)
        end
      end

      redirect_to teacher_path(@teacher), notice: "Perfil atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @teacher.destroy
    redirect_to teachers_url, notice: "Perfil removido permanentemente."
  end

  # MÉTODO: Vincula o Perfil (Teacher) a um Login (Professor do Devise)
  def link_login
    # O ID do professor vem do seletor (dropdown) na View index
    professor_id = params.dig(:teacher, :professor_id)
    professor = Professor.find_by(id: professor_id) if professor_id.present?
    
    if professor && @teacher.update(professor: professor)
      redirect_to teachers_path, notice: "Perfil de #{@teacher.name} vinculado ao login #{professor.email}!"
    else
      redirect_to teachers_path, alert: "Selecione um login válido para vincular."
    end
  end

  # MÉTODO: Remove a conexão entre o perfil e o login
  # Suporta PATCH ou DELETE conforme definido nas rotas
  def unlink_login
    if @teacher.update(professor_id: nil)
      redirect_to teachers_path, notice: "Vínculo de login para #{@teacher.name} removido com sucesso."
    else
      redirect_to teachers_path, alert: "Erro ao remover vínculo de login."
    end
  end

  private

  def set_teacher
    @teacher = Teacher.find(params[:id])
  end

  # Ajustado para permitir os campos corretos, professor_id e o array de disciplinas
  def teacher_params
    # Adicionados campos comuns como :email, :phone, :bio, :status que vi no seu _form
    params.require(:teacher).permit(:name, :email, :phone, :bio, :status, :professor_id, subject_ids: [])
  end
end