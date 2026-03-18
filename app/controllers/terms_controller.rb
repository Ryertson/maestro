class TermsController < ApplicationController
  before_action :authenticate_professor!

  def update
    @term = Term.find(params[:id])
  
    if @term.update(term_params)
      respond_to do |format|
        format.html { redirect_to lessons_path, notice: "Bimestre atualizado com sucesso!" }
        format.json { render json: { success: true, message: "Sucesso!", term: @term } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @term.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def term_params
    # Permite apenas os campos que definimos para o bimestre
    params.require(:term).permit(:start_date, :end_date, :color)
  end
end