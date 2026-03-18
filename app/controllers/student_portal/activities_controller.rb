module StudentPortal
  class ActivitiesController < ApplicationController
    before_action :authenticate_student_user! # Garante que só alunos logados acessem
    before_action :set_student
    layout "student_portal"

    def index
      # 1. Filtro por Turma: O aluno só vê atividades da sua própria turma
      # Usamos 'where' para restringir o acesso baseado na classroom do aluno
      @activities = Activity.where(classroom_id: @student.classroom_id)

      # 2. Lógica do Filtro de Busca por Nome (mantida e integrada)
      if params[:query].present?
        @activities = @activities.where("name ILIKE ?", "%#{params[:query]}%")
      end

      # 3. Lógica do Filtro por Disciplina (clique nas abas)
      # Se o aluno clicar em uma aba de disciplina específica, filtramos aqui
      if params[:subject_id].present?
        @activities = @activities.where(subject_id: params[:subject_id])
      end

      # 4. Extração de Disciplinas Disponíveis (para gerar as abas na View)
      # Isso busca apenas as disciplinas que possuem atividades vinculadas a essa turma
      @available_subjects = Subject.where(id: Activity.where(classroom_id: @student.classroom_id).select(:subject_id).distinct)

      # 5. Ordenação: Alterado para ordenar por data (campo 'date' que validamos antes)
      @activities = @activities.order(date: :asc)
    end

    def show
      @activity = Activity.find(params[:id])
      # Busca a submissão (entrega) do aluno para esta atividade específica
      @submission = @student.student_activities.find_by(activity_id: @activity.id)
    end

    private

    def set_student
      # Busca o registro de Aluno associado ao usuário logado no Devise
      @student = current_student_user.student 
    end
  end
end