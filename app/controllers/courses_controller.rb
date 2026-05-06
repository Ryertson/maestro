class CoursesController < ApplicationController
  def index
    @courses = Course.all
    @total_classrooms_count = Classroom.count
    @course = Course.new
    
    # Carrega os dados para os quadros de Séries e Turmas (IDs)
    @levels = Level.all.order(:name)
    @level = Level.new
    @sections = Section.all.order(:name)
    @section = Section.new
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      redirect_to courses_path, notice: "Curso criado com sucesso!"
    else
      render :new
    end
  end

  # Método para salvar a série via formulário na página de Cursos
  def add_level
    @level = Level.new(level_params)
    if @level.save
      redirect_to courses_path, notice: "Série adicionada com sucesso!"
    else
      # Em caso de erro, recarrega o index com os dados necessários
      @courses = Course.all
      @total_classrooms_count = Classroom.count
      @levels = Level.all.order(:name)
      @sections = Section.all.order(:name)
      render :index
    end
  end

  private

  def course_params
    params.require(:course).permit(:name)
  end

  def level_params
    params.require(:level).permit(:name)
  end
end