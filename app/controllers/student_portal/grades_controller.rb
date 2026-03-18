class StudentPortal::GradesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  layout 'student_portal'

  def index
    @student = current_student_user.student

    if @student
      # Buscamos os pontos e incluímos a atividade relacionada
      @points_records = @student.student_points.includes(:activity).order(created_at: :desc)

      # Média Geral baseada na coluna 'points'
      @average_general = @points_records.average(:points).to_f.round(1)

      # Melhor desempenho
      best_record = @points_records.order(points: :desc).first
      @best_subject = best_record ? (best_record.activity&.name || "Atividade") : "N/A"

      # --- AJUSTE DE FREQUÊNCIA SEGURO ---
      begin
        if @student.respond_to?(:attendances) && @student.attendances.any?
          total = @student.attendances.count
          presences = @student.attendances.where(status: 'present').count rescue total
          @attendance = total > 0 ? ((presences.to_f / total) * 100).to_i : 100
        else
          @attendance = 100
        end
      rescue
        @attendance = 100
      end
      # ----------------------------------

      # --- LÓGICA DE GAMIFICAÇÃO (NOVO) ---
      @badges = []

      # Medalha de Rank (Baseada na Média)
      if @average_general >= 9.0
        @badges << { name: "Rank Diamante", icon: "bi-gem", color: "cyan", desc: "Excelência Acadêmica" }
      elsif @average_general >= 7.0
        @badges << { name: "Rank Ouro", icon: "bi-trophy", color: "gold", desc: "Desempenho Sólido" }
      else
        @badges << { name: "Rank Bronze", icon: "bi-shield", color: "purple", desc: "Em Evolução" }
      end

      # Medalha de Assiduidade
      if @attendance >= 95
        @badges << { name: "Fogo Eterno", icon: "bi-fire", color: "orange", desc: "Presença Impecável" }
      end

      # Medalha de Participação (Baseada no volume de registros)
      if @points_records.count >= 5
        @badges << { name: "Veterano", icon: "bi-award", color: "blue", desc: "+5 Atividades" }
      end
      # ------------------------------------

    else
      @points_records = []
      @average_general = 0.0
      @best_subject = "N/A"
      @attendance = 0
      @badges = []
    end

    render "student_portal/grades/grades"
  end

  def create
    @point = StudentPoint.find_or_initialize_by(
      student_id: grade_params[:student_id],
      activity_id: grade_params[:activity_id]
    )
    @point.points = grade_params[:value] if grade_params[:value].present?

    respond_to do |format|
      if @point.save
        format.json { render json: { status: 'success', point: @point }, status: :ok }
        format.html { redirect_back fallback_location: root_path, notice: "Salvo!" }
      else
        format.json { render json: { status: 'error' }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: "Erro!" }
      end
    end
  end

  private

  def grade_params
    params.require(:grade).permit(:value, :student_id, :activity_id, :name)
  end
end