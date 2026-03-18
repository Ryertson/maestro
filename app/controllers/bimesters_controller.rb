class BimestersController < ApplicationController
  def create
    @bimester = Bimester.new(bimester_params)
    if @bimester.save
      redirect_to planning_path, notice: "Bimestre configurado com sucesso!"
    else
      redirect_to planning_path, alert: "Erro ao salvar bimestre. Verifique as datas."
    end
  end

  def destroy
    @bimester = Bimester.find(params[:id])
    @bimester.destroy
    redirect_to planning_path, notice: "Bimestre removido."
  end

  private

  def bimester_params
    params.require(:bimester).permit(:name, :start_date, :end_date, :color)
  end
end
