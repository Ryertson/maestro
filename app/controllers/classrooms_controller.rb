class ClassroomsController < ApplicationController
  # Autenticador correto do projeto (escopo professor)
  before_action :authenticate_professor! 
  before_action :set_classroom, only: %i[ show edit update destroy grading transfer_students ]

  def index
    # Atualizado para usar :level no lugar de :grade
    @classrooms = Classroom.includes(:course, :level, :teacher).all
  end

  def show
  end

  def new
    @classroom = Classroom.new
    @levels = Level.all.order(:name) 
    @courses = Course.all
    @sections = Section.all
  end

  def edit
  end

  def create
    @classroom = Classroom.new(classroom_params)
    if @classroom.save
      redirect_to classrooms_path, notice: "Turma criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @classroom.update(classroom_params)
      redirect_to classrooms_path, notice: "Turma atualizada com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @classroom.destroy
    redirect_to classrooms_path, notice: "Turma excluída.", status: :see_other
  end

  def grading
    # 1. Identificação do Professor (ID ou E-mail)
    @teacher = Teacher.find_by(user_id: current_professor.id)
    @teacher ||= Teacher.find_by(email: current_professor.email)
  
    # 2. Busca da disciplina específica vinculada à turma
    if @teacher
      @classroom_subject = @classroom.classroom_subjects.find_by(teacher_id: @teacher.id)
      @current_subject = @classroom_subject&.subject
    end

    # DEBUG PARA MONITORAMENTO NO TERMINAL
    puts "--- DEBUG MAESTRO ---"
    puts "ID Login: #{current_professor.id} | Email: #{current_professor.email}"
    puts "Perfil Teacher: #{@teacher&.name || 'NÃO ENCONTRADO'}"
    puts "Disciplina: #{@current_subject&.name || 'NÃO DETECTADA'}"
    puts "---------------------"

    # 3. Carregamento de dados da Turma
    @students = @classroom.students.order(:name)
    @my_subjects = @classroom.course&.subjects || []

    # --- ATUALIZAÇÃO CRÍTICA ---
    # Como você renomeou o modelo de Séries para Level, a classe 'Grade' não existe mais.
    # Se esta variável @grades deveria carregar as NOTAS (scores) dos alunos, 
    # você precisará garantir que tenha um modelo específico para notas.
    # Caso contrário, se era para carregar dados da série, mude para Level:
    @grades = Grade.where(classroom_id: @classroom.id) || [] 
  end

  def transfer_students
    target_classroom = Classroom.find_by(id: params[:target_classroom_id])
    student_ids = params[:student_ids]

    if target_classroom && student_ids.present?
      # Atualiza todos os alunos selecionados de uma vez
      Student.where(id: student_ids).update_all(classroom_id: target_classroom.id)
    
      redirect_to classroom_path(@classroom), 
                  notice: "#{student_ids.count} aluno(s) transferido(s) com sucesso para #{target_classroom.display_name}!"
    else
      redirect_to classroom_path(@classroom), 
                  alert: "Erro: Selecione os alunos e a turma de destino."
    end
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def classroom_params
    # --- ATUALIZAÇÃO 2: Trocado :grade_id por :level_id ---
    params.require(:classroom).permit(:course_id, :level_id, :section_id, :teacher_id)
  end
end