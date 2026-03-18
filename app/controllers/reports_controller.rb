class ReportsController < ApplicationController
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
end
