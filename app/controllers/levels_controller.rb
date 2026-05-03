class LevelsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    # Busca ou inicia apenas pelo nome para evitar o erro de colunas de notas
    @level = Level.find_or_initialize_by(name: level_params[:name])

    respond_to do |format|
      if @level.save
        format.html { redirect_back fallback_location: academic_settings_path, notice: "Série salva com sucesso!" }
        format.json { render json: { status: 'success', level: @level }, status: :ok }
      else
        # Se cair aqui, o erro aparecerá no alerta do Maestro
        format.html { redirect_back fallback_location: academic_settings_path, alert: "Erro: #{@level.errors.full_messages.join(', ')}" }
        format.json { render json: { status: 'error', errors: @level.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @level = Level.find(params[:id])
    @level.destroy
    redirect_to academic_settings_path, notice: "Série excluída com sucesso."
  end

  private

  def level_params
    # Permitimos apenas o nome para o cadastro de séries escolar
    params.require(:level).permit(:name)
  end
end