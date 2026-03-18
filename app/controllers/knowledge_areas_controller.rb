class KnowledgeAreasController < ApplicationController
  def create
    @area = KnowledgeArea.new(area_params)
    if @area.save
      redirect_to academic_settings_path, notice: "Área '#{@area.name}' criada com sucesso!"
    else
      redirect_to academic_settings_path, alert: "Erro ao criar área: #{@area.errors.full_messages.to_sentence}"
    end
  end

  private

  def area_params
    params.require(:knowledge_area).permit(:name, :color)
  end
end