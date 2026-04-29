class StudentPointsController < ApplicationController
  before_action :authenticate_professor!
  
  def index
    # 1. Escopo de Turmas (Admin vê todas, Professor vê as suas)
    if current_professor.admin?
      @classrooms = Classroom.all
    else
      # Busca o perfil de Teacher vinculado ao Professor logado
      teacher_profile = current_professor.teacher || Teacher.find_by(email: current_professor.email)
      
      if teacher_profile
        @classrooms = Classroom.joins(:classroom_subjects)
                               .where(classroom_subjects: { teacher_id: teacher_profile.id })
                               .distinct
      else
        @classrooms = Classroom.none
      end
    end

    # 2. Identifica a Turma Atual
    if params[:classroom_id].present?
      @current_classroom = @classrooms.find_by(id: params[:classroom_id])
    end

    # Se não houver classroom_id ou se o ID passado não for permitido, pegamos a primeira da lista
    @current_classroom ||= @classrooms.first

    # 3. Dados para a tabela (LINHA ATUALIZADA AQUI)
    if @current_classroom
      @activities = Activity.where(classroom_id: @current_classroom.id).order(:date)
      # Usamos o includes para carregar os pontos de uma vez e evitar lentidão
      @students = @current_classroom.students.includes(:student_points).order(:name)
    else
      @activities = []
      @students = []
    end
  end
  
  # Ação para salvar via AJAX
  def update_score
    submitted_points = params[:points].to_s.gsub(',', '.').to_f

    @point = StudentPoint.find_or_initialize_by(
      student_id: params[:student_id], 
      activity_id: params[:activity_id]
    )
    
    @point.points = submitted_points
    
    if @point.save
      student = Student.find(params[:student_id])
      activity_context = Activity.find(params[:activity_id])
      relevant_activity_ids = Activity.where(classroom_id: activity_context.classroom_id).pluck(:id)
      
      nova_media_calculada = student.calcular_nota_com_pesos(relevant_activity_ids)
      
      render json: { 
        status: 'success', 
        points: @point.points,
        total_acumulado: nova_media_calculada,
        nova_media: nova_media_calculada
      }
    else
      render json: { 
        status: 'error', 
        message: @point.errors.full_messages.to_sentence 
      }, status: :unprocessable_entity
    end
  end
end