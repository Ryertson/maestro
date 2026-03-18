class PlanningController < ApplicationController
  def index
    # 1️⃣ Lógica de Navegação do Calendário (Setas)
    @view_date = params[:date] ? Date.parse(params[:date]) : Date.today
    @start_of_calendar = @view_date.beginning_of_month.beginning_of_week
    @end_of_calendar = @view_date.end_of_month.end_of_week

    # 2️⃣ Base da consulta de Lições
    @lessons = Lesson.order(:date)

    if params[:course].present?
      @lessons = @lessons.where(course: params[:course])
    end

    if params[:grade_level].present?
      @lessons = @lessons.where(grade_level: params[:grade_level])
    end

    # 3️⃣ Busca de Bimestres e Atividades para o Calendário
    @bimesters = Bimester.order(:start_date)
    @activities = Activity.where(date: @start_of_calendar..@end_of_calendar)

    # 4️⃣ Mapeamento de Eventos para o Calendário
    @calendar_events = {}

    @lessons.where(date: @start_of_calendar..@end_of_calendar).each do |l|
      @calendar_events[l.date] ||= []
      @calendar_events[l.date] << { name: l.topic_name, type: 'lesson', color: 'primary' }
    end

    @activities.each do |a|
      if a.date.present?
        date_key = a.date.to_date
        @calendar_events[date_key] ||= []
        @calendar_events[date_key] << { name: a.name, type: 'activity', color: 'danger', id: a.id }
      end
    end

    # 5️⃣ Cálculos para o Dashboard
    @total_aulas = @lessons.count
    @prontas = @lessons.where(status: "Pronto").count
    @com_atividade = @lessons.where(has_activity: true).count
    @pendentes = @total_aulas - @prontas

    # Usamos :activity (singular) para o JOIN (nome da associação no model)
    # Agora usamos o plural aqui também para bater com o novo nome no Model
    @pending_planned_activities = Lesson.where(has_activity: true)
                                    .left_outer_joins(:activities)
                                    .where(activities: { id: nil })

    @percentual_geral = @total_aulas.positive? ? ((@prontas.to_f / @total_aulas) * 100).round : 0
    @percentual_atividades = @total_aulas.positive? ? ((@com_atividade.to_f / @total_aulas) * 100).round : 0
    
    @series_options = ["1ª Série", "2ª Série", "3ª Série"]
    @courses_options = ["Agroecologia", "Análises Clínicas", "Informática"]
  end
end