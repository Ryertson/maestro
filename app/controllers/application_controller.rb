class ApplicationController < ActionController::Base
  # 1. Ajuste na trava de segurança: Adicionado bypass para que o aluno logado não seja tratado como professor deslogado
  before_action :authenticate_professor!, unless: -> { devise_controller? || student_user_signed_in? }
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  helper_method :current_teacher_profile
  helper_method :current_view_mode # Registrado para ser usado nas Views também

  layout :layout_by_resource

  def current_teacher_profile
    return nil unless current_professor
    # Tenta encontrar o registro de professor na tabela 'teachers' 
    # que tenha o mesmo e-mail da conta logada no Devise
    @current_teacher_profile ||= Teacher.find_by(email: current_professor.email) if professor_signed_in?
  end

  # --- MÉTODO: Define se o sistema exibe visão de Professor ou Admin ---
  def current_view_mode
    return :modo_professor unless current_professor
    
    # Se o professor não for administrador, ele está sempre no modo professor
    return :modo_professor unless current_professor.admin?
    
    # Se for admin, retorna o símbolo do modo salvo no banco (:modo_admin ou :modo_professor)
    current_professor.view_mode.to_sym
  rescue
    :modo_professor
  end

  protected

  def configure_permitted_parameters
    # Permissões para o cadastro (Sign Up)
    # Adicionamos :student_id para que o Aluno consiga se vincular ao perfil criado pelo professor
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :student_id])
    
    # Permissões para atualização de conta (Account Update)
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :student_id])
  end

  # --- INJEÇÃO DE LOGICA: Redirecionamento pós-login correto ---
  def after_sign_in_path_for(resource)
    if resource.is_a?(StudentUser)
      student_portal_root_path
    elsif resource.is_a?(Professor)
      root_path
    else
      super
    end
  end

  # --- AJUSTE: Evita redirecionar o Professor para o login do Aluno ao sair ---
  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :student_user
      new_student_user_session_path
    elsif resource_or_scope == :professor
      new_professor_session_path
    else
      root_path
    end
  end

  private

  # --- INJEÇÃO DE LOGICA: Garante o carregamento dos estilos CSS corretos para o login do aluno ---
  def layout_by_resource
    if devise_controller? && resource_name == :student_user
      "student_portal"
    else
      "application"
    end
  end
end