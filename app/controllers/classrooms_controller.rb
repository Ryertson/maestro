class ClassroomsController < ApplicationController
  before_action :authenticate_professor! 
  before_action :set_classroom, only: %i[ show edit update destroy grading transfer_students ]

  def index
    @classrooms = Classroom.includes(:course, :level, :teacher).all
  end

  def show
  end

  def new
    @classroom = Classroom.new
    set_form_data # Método auxiliar para carregar as séries, cursos e seções
  end

  def edit
    set_form_data # Garante que as séries apareçam ao editar uma turma
  end

  def create
    @classroom = Classroom.new(classroom_params)
    if @classroom.save
      redirect_to classrooms_path, notice: "Turma criada com sucesso!"
    else
      set_form_data # ESSENCIAL: Se o salvamento falhar, recarrega as séries para a View não quebrar
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @classroom.update(classroom_params)
      redirect_to classrooms_path, notice: "Turma atualizada com sucesso!"
    else
      set_form_data # ESSENCIAL: Garante que as séries continuem lá se a atualização falhar
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @classroom.destroy
    redirect_to classrooms_path, notice: "Turma excluída.", status: :see_other
  end

  def grading
    @teacher = Teacher.find_by(user_id: current_professor.id)
    @teacher ||= Teacher.find_by(email: current_professor.email)
  
    if @teacher
      @classroom_subject = @classroom.classroom_subjects.find_by(teacher_id: @teacher.id)
      @current_subject = @classroom_subject&.subject
    end

    @students = @classroom.students.order(:name)
    @my_subjects = @classroom.course&.subjects || []
    
    # Aqui mantemos Grade se este modelo for o de NOTAS e não o de SÉRIES
    @grades = Grade.where(classroom_id: @classroom.id) || [] 
  end

  def transfer_students
    target_classroom = Classroom.find_by(id: params[:target_classroom_id])
    student_ids = params[:student_ids]

    if target_classroom && student_ids.present?
      Student.where(id: student_ids).update_all(classroom_id: target_classroom.id)
      redirect_to classroom_path(@classroom), 
                  notice: "#{student_ids.count} aluno(s) transferido(s) com sucesso!"
    else
      redirect_to classroom_path(@classroom), 
                  alert: "Erro: Selecione os alunos e a turma de destino."
    end
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  # Método auxiliar para evitar repetição de código (DRY)
  def set_form_data
    @levels = Level.all.order(:name) 
    @courses = Course.all
    @sections = Section.all
  end

  def classroom_params
    # :level_id deve estar aqui para o Rails permitir o salvamento
    params.require(:classroom).permit(:name, :course_id, :level_id, :section_id, :teacher_id)
  end
end