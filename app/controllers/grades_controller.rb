class GradesController < ApplicationController
  # Ignora a verificação de token para permitir que o JavaScript (fetch) salve as notas rapidamente
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    # Lógica inteligente: Se já existir uma nota para este Aluno + Matéria + Turma, nós a atualizamos.
    # Caso contrário, criamos uma nova. Isso evita duplicidade no boletim.
    @grade = Grade.find_or_initialize_by(
      student_id: grade_params[:student_id],
      subject_id: grade_params[:subject_id],
      classroom_id: grade_params[:classroom_id]
    )

    # Atribui o valor da nota (ou o nome, se você ainda estiver usando como 'Série')
    @grade.value = grade_params[:value] if grade_params[:value].present?
    @grade.name  = grade_params[:name]  if grade_params[:name].present?

    respond_to do |format|
      if @grade.save
        # Resposta para o Boletim Rápido (JavaScript/JSON)
        format.json { render json: { status: 'success', grade: @grade }, status: :ok }
        # Resposta para formulários normais (HTML)
        format.html { redirect_back fallback_location: root_path, notice: "Salvo com sucesso!" }
      else
        format.json { render json: { status: 'error', errors: @grade.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: "Erro ao salvar." }
      end
    end
  end

  private

  def grade_params
    # Permitimos tanto os campos da Nota (value, student_id, etc) quanto o campo Name (caso seja usado como Série)
    params.require(:grade).permit(:value, :student_id, :subject_id, :classroom_id, :name)
  end
end