class ProfessorsController < ApplicationController
  # Adicionado authenticate_professor! para garantir segurança na troca de visão
  before_action :authenticate_professor!
  before_action :set_professor, only: %i[ show edit update destroy ]

  # GET /professors or /professors.json
  def index
    @professors = Professor.all
  end

  # GET /professors/1 or /professors/1.json
  def show
  end

  # GET /professors/new
  def new
    @professor = Professor.new
  end

  # GET /professors/1/edit
  def edit
  end

  # POST /professors or /professors.json
  def create
    @professor = Professor.new(professor_params)

    respond_to do |format|
      if @professor.save
        format.html { redirect_to @professor, notice: "Professor was successfully created." }
        format.json { render :show, status: :created, location: @professor }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @professor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /professors/1 or /professors/1.json
  def update
    respond_to do |format|
      if @professor.update(professor_params)
        format.html { redirect_to @professor, notice: "Professor was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @professor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @professor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /professors/1 or /professors/1.json
  def destroy
    @professor.destroy!

    respond_to do |format|
      format.html { redirect_to professors_path, notice: "Professor was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # --- NOVO MÉTODO: Alternar entre Modo Professor e Modo Admin ---
  def toggle_view_mode
    if current_professor.admin?
      # Inverte o modo usando os métodos gerados pelo enum no model
      novo_modo = current_professor.modo_professor? ? :modo_admin : :modo_professor
      
      if current_professor.update(view_mode: novo_modo)
        mode_name = novo_modo == :modo_admin ? "Administrador" : "Professor"
        redirect_back fallback_location: root_path, notice: "Visão alterada para: Modo #{mode_name}"
      else
        redirect_back fallback_location: root_path, alert: "Erro ao alterar modo de visão."
      end
    else
      redirect_to root_path, alert: "Acesso restrito aos administradores."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_professor
      # Mantive o params.expect se você estiver usando Rails 8, mas deixei compatível
      @professor = Professor.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def professor_params
      # Permitindo também o view_mode caso queira editar pelo formulário algum dia
      params.require(:professor).permit(:nome, :matricula, :view_mode)
    end
end