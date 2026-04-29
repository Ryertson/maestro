class ReportsController < ApplicationController
  before_action :authenticate_professor!

  def index
    # 1. Captura os filtros da URL
    @selected_course = params[:course]
    @selected_grade = params[:grade_level]
    
    # 2. Busca todos os bimestres para montar as abas ou colunas
    @bimesters = Bimester.order(:start_date)
    
    # 3. Define o bimestre atual (ou o primeiro caso nenhum seja selecionado)
    @current_bimester = params[:bimester_id].present? ? Bimester.find(params[:bimester_id]) : @bimesters.first

    # 4. Busca os alunos filtrados
    @students = Student.all
    @students = @students.where(course: @selected_course) if @selected_course.present?
    @students = @students.where(grade: @selected_grade) if @selected_grade.present?
    @students = @students.order(:name)

    # 5. Busca as atividades que pertencem ao bimestre selecionado
    if @current_bimester
      @activities = Activity.where(date: @current_bimester.start_date..@current_bimester.end_date)
      @activities = @activities.where(course: @selected_course) if @selected_course.present?
    else
      @activities = []
    end
  end

  # NOVA ACTION: Página de Resultados (Cards por Sala)
  def results
    # 1. Escopo de Turmas: Admin vê tudo, Professor vê apenas as dele
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

  # NOVA ACTION: Gerar PDF de alunos em Recuperação
  def export_recuperacao
    @classroom = Classroom.find(params[:classroom_id])
    
    # Pegamos os IDs das atividades da turma para o cálculo da média
    activity_ids = @classroom.activities.pluck(:id)
    
    # Filtramos os alunos com média menor que 6.0 usando o método do Model Student
    @students_recuperacao = @classroom.students.select do |student|
      student.calcular_nota_com_pesos(activity_ids) < 6.0
    end

    respond_to do |format|
      format.html # Opcional: para visualizar no navegador
      format.pdf do
        render pdf: "Recuperacao_#{@classroom.display_name}_#{Date.today.strftime('%d_%m_%Y')}",
               template: "reports/recuperacao_pdf",
               layout: 'pdf', # Certifique-se de ter um layout pdf.html.erb ou use false
               disposition: 'attachment' # Força o download
      end
    end
  end

  # ACTION: Listagem de Atividades Perdidas (Tela do Sistema)
  def lost_activities
    if current_professor.admin?
      @classrooms = Classroom.all.includes(:students, :activities)
    else
      teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)
      if teacher_profile
        @classrooms = Classroom.joins(:classroom_subjects)
                               .where(classroom_subjects: { teacher_id: teacher_profile.id })
                               .distinct.includes(:students, :activities)
      else
        @classrooms = Classroom.none
      end
    end
  end

  # NOVA ACTION: Versão para Impressão/PDF de Atividades Perdidas
  def lost_activities_print
    if current_professor.admin?
      @classrooms = Classroom.all.includes(:students, :activities)
    else
      teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)
      if teacher_profile
        @classrooms = Classroom.joins(:classroom_subjects)
                               .where(classroom_subjects: { teacher_id: teacher_profile.id })
                               .distinct.includes(:students, :activities)
      else
        @classrooms = Classroom.none
      end
    end

    # Renderiza usando o layout limpo de impressão que criamos
    render layout: 'print'
  end
end