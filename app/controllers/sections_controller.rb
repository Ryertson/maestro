class SectionsController < ApplicationController
  def create
    @section = Section.new(section_params)
    if @section.save
      redirect_to courses_path, notice: "Seção/Turma cadastrada!"
    else
      redirect_to courses_path, alert: "Erro ao salvar seção."
    end
  end

  def destroy
    @section = Section.find(params[:id])
    @section.destroy

    respond_to do |format|
      format.html { redirect_to academic_settings_path, notice: "Identificador excluído com sucesso." }
      format.json { head :no_content }
    end
  end

  private
  def section_params
    params.require(:section).permit(:name)
  end
end
