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
    
    # Normaliza o status vindo do clique na imagem
    status_bruto = params[:status].to_s.downcase.strip

    if status_bruto == 'clear'
      @attendance.destroy if @attendance.persisted?
      @attendance = Attendance.new(student: @student, date: params[:date], status: 'cleared')
      sucesso = true
    else
      # MAPEAMENTO EXATO: Traduz o que você vê na imagem para o que o banco precisa
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
        format.js   # Para atualização em tempo real na planilha
        format.html { redirect_to students_path(classroom_id: @classroom_id) }
      end
    else
      # Se houver erro de validação, ele aparecerá no seu terminal (rails s)
      Rails.logger.error "❌ ERRO DE SALVAMENTO: #{@attendance.errors.full_messages}"
      render json: @attendance.errors, status: :unprocessable_entity
    end
  end
end