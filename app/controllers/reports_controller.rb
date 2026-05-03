class ReportsController < ApplicationController
  before_action :authenticate_professor!

  # 1. Página Geral de Relatórios (com filtros)
  def index
    # Captura os filtros da URL
    @selected_course = params[:course]
    @selected_grade = params[:grade_level]
    
    # Busca todos os bimestres para montar as abas ou colunas
    @bimesters = Bimester.order(:start_date)
    
    # Define o bimestre atual (ou o primeiro caso nenhum seja selecionado)
    @current_bimester = params[:bimester_id].present? ? Bimester.find(params[:bimester_id]) : @bimesters.first

    # Busca os alunos filtrados
    @students = Student.all
    @students = @students.where(course: @selected_course) if @selected_course.present?
    @students = @students.where(grade: @selected_grade) if @selected_grade.present?
    @students = @students.order(:name)

    # Busca as atividades que pertencem ao bimestre selecionado
    if @current_bimester
      @activities = Activity.where(date: @current_bimester.start_date..@current_bimester.end_date)
      @activities = @activities.where(course: @selected_course) if @selected_course.present?
    else
      @activities = []
    end
  end

  # 2. Página de Resultados (Exibição dos Cards por Sala)
  def results
    # Escopo de Turmas: Admin vê tudo, Professor vê apenas as dele
    if current_professor.admin?
      @classrooms = Classroom.all.includes(:course, :students, :activities)
    else
      # Busca o perfil de Teacher vinculado ao Professor (usando o e-mail como chave)
      teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)
    
      if teacher_profile
        # Filtra turmas onde o professor leciona pelo menos uma disciplina
        @classrooms = Classroom.joins(:classroom_subjects)
                               .where(classroom_subjects: { teacher_id: teacher_profile.id })
                               .distinct
                               .includes(:course, :students, :activities)
      else
        @classrooms = Classroom.none
      end
    end
  end

  # 3. Gerar HTML/PDF de alunos em Recuperação
  def export_recuperacao
    @classroom = Classroom.find(params[:classroom_id])
    activity_ids = @classroom.activities.pluck(:id)
    
    @students_recuperacao = @classroom.students.select do |student|
      student.nota_da_prova(activity_ids) < 6.0
    end

    respond_to do |format|
      format.html { render template: "reports/recuperacao_pdf", layout: "pdf" }
    end
  end

  # 4. Versão para Impressão/PDF de Atividades Perdidas (Ajustado para o seu botão)
  def lost_activities_print
    @classroom = Classroom.find(params[:classroom_id])
    @activities = @classroom.activities.order(:date)
    
    # Filtra alunos que têm pelo menos uma atividade com nota 0
    @students_com_pendencias = @classroom.students.order(:name).select do |student|
      @activities.any? { |activity| student.nota_na_atividade(activity.id) == 0 }
    end

    respond_to do |format|
      format.html { render template: "reports/lost_activities_print", layout: "pdf" }
    end
  end

  # 5. Método auxiliar (caso seu sistema use este nome de rota especificamente)
  def export_atividades_perdidas
    @classroom = Classroom.find(params[:classroom_id])
    @activities = @classroom.activities.order(:date)
  
    @students_com_pendencias = @classroom.students.order(:name).select do |student|
      @activities.any? { |activity| student.nota_na_atividade(activity.id) == 0 }
    end

    render template: "reports/atividades_perdidas_pdf", layout: "pdf"
  end

  # Esta é a ação que carrega a página principal de Atividades Perdidas
  def lost_activities
    # 1. Escopo de Turmas: Professor vê apenas as turmas onde leciona
    teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)

    if teacher_profile
      @classrooms = Classroom.joins(:classroom_subjects)
                             .where(classroom_subjects: { teacher_id: teacher_profile.id })
                             .distinct
                             .includes(:course, :students, :activities)
    else
      @classrooms = [] # Garante que não seja nil, evitando o erro 'each' for nil
    end
  end

end # Fim da classe ReportsController