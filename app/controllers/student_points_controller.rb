class StudentPointsController < ApplicationController
  before_action :authenticate_professor!

  def index
    # 1. Escopo de Turmas (Admin vê todas, Professor vê as suas)
    @classrooms = if current_professor.admin?
                    Classroom.all
                  else
                    # Ajuste aqui conforme sua associação (ex: Classroom.joins(:teachers).where(teachers: { id: current_teacher_profile.id }))
                    Classroom.all 
                  end

    # 2. Turma Atual
    @current_classroom = params[:classroom_id].present? ? Classroom.find_by(id: params[:classroom_id]) : @classrooms.first

    if @current_classroom
      # 3. Buscamos todas as atividades desta turma (ordenadas por data)
      @activities = Activity.where(classroom_id: @current_classroom.id).order(:date)
      
      # 4. Buscamos os alunos com seus pontos já carregados para evitar o erro N+1
      @students = @current_classroom.students.includes(:student_points).order(:name)
    else
      @activities = []
      @students = []
    end
  end
  
  # Ação para salvar via AJAX (sem recarregar a página)
  def update_score
    # Sanitização básica do valor de pontos
    submitted_points = params[:points].to_s.gsub(',', '.').to_f

    @point = StudentPoint.find_or_initialize_by(
      student_id: params[:student_id], 
      activity_id: params[:activity_id]
    )
    
    @point.points = submitted_points
    
    if @point.save
      # Identificamos o aluno e as atividades relevantes para recalcular a média com a nova lógica
      student = Student.find(params[:student_id])
      
      # Buscamos os IDs das atividades que pertencem à mesma turma da atividade que foi editada
      # Isso garante que a média seja calculada apenas sobre o contexto correto
      activity_context = Activity.find(params[:activity_id])
      relevant_activity_ids = Activity.where(classroom_id: activity_context.classroom_id).pluck(:id)
      
      # Chamamos o método que criamos no Model para obter a média estruturada
      nova_media_calculada = student.calcular_nota_com_pesos(relevant_activity_ids)
      
      render json: { 
        status: 'success', 
        points: @point.points,
        total_acumulado: nova_media_calculada, # Enviamos a média como 'total_acumulado' para o JS reconhecer
        nova_media: nova_media_calculada      # Enviamos também com o nome explícito por segurança
      }
    else
      render json: { 
        status: 'error', 
        message: @point.errors.full_messages.to_sentence 
      }, status: :unprocessable_entity
    end
  end
end