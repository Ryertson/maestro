class AttendancesController < ApplicationController
  def create
    @student = Student.find(params[:student_id])
    
    # Busca ou inicializa vinculando aluno e aula
    @attendance = Attendance.find_or_initialize_by(
      student_id: @student.id, 
      lesson_id: params[:lesson_id]
    )
    
    @attendance.date = params[:date]
    @attendance.classroom_id = params[:classroom_id]
    @classroom_id = params[:classroom_id]
    
    # Normaliza o status vindo do clique
    status_bruto = params[:status].to_s.downcase.strip

    if status_bruto == 'clear'
      @attendance.destroy if @attendance.persisted?
      # Após limpar, ele volta a ser um objeto novo para a View saber que está 'vazio'
      @attendance = Attendance.new(student: @student, date: params[:date], status: 'cleared')
      sucesso = true
    else
      @attendance.status = case status_bruto
                           when 'present'   then 'Presente'
                           when 'absent'    then 'Faltou'
                           when 'late'      then 'Atrasado'
                           when 'justified' then 'Justificada'
                           else status_bruto.capitalize
                           end
      sucesso = @attendance.save
    end

    if sucesso
      respond_to do |format|
        format.js   # Isso garantirá que o quadrado mude de cor sem recarregar a página
        format.html { redirect_to students_path(classroom_id: @classroom_id) }
      end
    else
      Rails.logger.error "❌ ERRO DE SALVAMENTO: #{@attendance.errors.full_messages}"
      render json: @attendance.errors, status: :unprocessable_entity
      format.json { render json: { status: 'success', attendance: @attendance } }
    end
  end
end