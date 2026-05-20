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
        # ATUALIZAÇÃO: Adicionamos o turbo_stream para atualizar a UI sem recarregar
        format.turbo_stream
        
        # Mantemos o HTML como fallback (caso o navegador não suporte Turbo)
        format.html do 
          redirect_to students_path(
            classroom_id: @classroom_id, 
            month_year: params[:date].to_date.strftime("%Y-%m"),
            format: :html
          ), notice: "Frequência atualizada com sucesso!"
        end
        
        # Mantemos o JSON para usos futuros ou integrações
        format.json { render json: { status: 'success', attendance: @attendance } }
      end
    else
      Rails.logger.error "❌ ERRO DE SALVAMENTO: #{@attendance.errors.full_messages}"
      respond_to do |format|
        format.html { redirect_to students_path(classroom_id: @classroom_id), alert: "Erro ao salvar: #{@attendance.errors.full_messages.join(', ')}" }
        format.json { render json: @attendance.errors, status: :unprocessable_entity }
      end
    end
  end
end