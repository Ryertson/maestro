Rails.application.routes.draw do
  # 1. Autenticação (Scopes Separados)
  devise_for :student_users
  devise_for :professors

  # 2. Raiz e Saúde do App
  root to: "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # 3. ÁREA DO ESTUDANTE (Portal Exclusivo - Dark Neon)
  # O caminho 'meu_portal' gera as rotas que o aluno usará após o login
  namespace :student_portal, path: 'meu_portal' do
    # Define student_portal_root_path usado no ApplicationController
    root to: 'dashboards#index'
    
    # Isso garante que dashboards_path exista dentro do namespace
    resources :dashboards, except: [:show] 
    
    resources :activities, only: [:index, :show]
    resources :attendances, only: [:index]
    resources :grades, only: [:index]
  end

  # 4. Dashboard e Planejamento Geral (Professor/Admin)
  get "dashboard/index", to: "dashboard#index", as: :dashboard_page
  get "planning", to: "lessons#index", as: :planning
  get "reports", to: "reports#index", as: :reports

  # 5. Gestão Acadêmica Superior (Admin)
  get 'configuracoes_academicas', to: 'academic_settings#index', as: :academic_settings
  resources :knowledge_areas, only: [:create]
  resources :subjects, only: [:create]
  resources :bimesters, only: [:index, :create, :update, :destroy]
  resources :terms, only: [:update]
  
  # Gestão de Datas Importantes (Provas, Feriados, Reuniões)
  resources :academic_events, except: [:show]

  # 6. Corpo Docente (Cadastro de Professores e Atribuições)
  resources :teachers do
    member do
      patch :link_login
      delete :unlink_login
      get :unlink_login
    end
    resources :teacher_assignments, only: [:create, :destroy]
  end
  
  resources :professors, only: [:index, :show, :edit, :update]

  resources :academic_settings do
    member do
      patch :reset_password
    end
  end

  # 7. Estrutura Escolar e Turmas (ATUALIZADO PARA PERMITIR EXCLUSÃO)
  resources :grades, only: [:create, :destroy]
  resources :sections, only: [:create, :destroy]
  resources :courses
  resources :students, only: [:destroy]
  
  resources :classrooms do
    member do
      get :grading
      post :transfer_students
    end

    resources :grades, only: [:create]
    resources :lessons, only: [:index, :new]
    resources :activities, only: [:index, :new]
  end

  resources :classroom_subjects

  # 8. Alunos e Frequência
  resources :students do
    collection do
      post :import
      get :download_template
      get :allocate_classrooms
      # Essencial para a ativação de conta do aluno via AJAX
      get :index, defaults: { format: :json }
    end
    resources :attendances, only: [:create]
  end
  
  resources :attendances, only: [:create]

  # 9. Planejamento de Aulas e Conteúdos
  resources :lessons
  resources :topics

  # 10. Atividades, Avaliações e Notas (CONSOLIDADO)
  resources :activities do
    collection do
      post :save_submissions
    end
    
    member do
      get :grading
      # Permite a mudança de status individual por aluno
      patch :update_status
      patch :mark_as_corrected
    end
  end

  resources :students, only: [:index, :show] do
    member do
      get :report 
    end
  end

  # 11. Mapa de Pontuação e Desempenho (Visão de Grade)
  resources :student_points, only: [:index] do
    collection do
      post :update_score
    end
  end

  # 12. Funções Auxiliares e AJAX
  post 'update_student_points', to: 'student_points#update_score'
  post 'toggle_view_mode', to: 'professors#toggle_view_mode'

  get 'resultados', to: 'reports#results', as: :results_report
  get 'export_recuperacao/:classroom_id', to: 'reports#export_recuperacao', as: :export_recuperacao
  get 'atividades_perdidas', to: 'reports#lost_activities', as: :lost_activities_report
  get 'atividades_perdidas_print', to: 'reports#lost_activities_print', as: :lost_activities_print

end