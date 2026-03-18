class AcademicSettingsController < ApplicationController
  before_action :authenticate_professor!
  before_action :ensure_admin!

  def index
    @knowledge_areas = KnowledgeArea.all.includes(:subjects)
    @new_area = KnowledgeArea.new
    @new_subject = Subject.new
  end

  private

  def ensure_admin!
    unless current_professor.admin?
      redirect_to root_path, alert: "Acesso negado! Apenas administradores podem acessar esta página."
    end
  end
end
