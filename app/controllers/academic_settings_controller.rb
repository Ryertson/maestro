class AcademicSettingsController < ApplicationController
  before_action :authenticate_professor!
  before_action :ensure_admin!

  def index
    @knowledge_areas = KnowledgeArea.all.includes(:subjects)
    @new_area = KnowledgeArea.new
    @new_subject = Subject.new
    @all_professors = Professor.where.not(id: current_professor.id).order(:name)
  end

  def reset_password
    @professor = Professor.find(params[:id])
    default_password = "Ecit@#{Time.current.year}" # Gera algo como Ecit@2026
    
    if @professor.update(password: default_password, password_confirmation: default_password)
      redirect_to academic_settings_path, notice: "Senha de #{@professor.name} resetada para: #{default_password}"
    else
      redirect_to academic_settings_path, alert: "Erro ao resetar senha."
    end
  end

  private

  def ensure_admin!
    unless current_professor.admin?
      redirect_to root_path, alert: "Acesso negado! Apenas administradores podem acessar esta página."
    end
  end
end
