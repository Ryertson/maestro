# app/controllers/academic_events_controller.rb
class AcademicEventsController < ApplicationController
  before_action :authenticate_professor!
  before_action :authorize_admin! # Trava de segurança para apenas Admin
  before_action :set_academic_event, only: [:edit, :update, :destroy]

  def index
    @academic_events = AcademicEvent.order(event_date: :asc)
  end

  def new
    @academic_event = AcademicEvent.new
  end

  def create
    @academic_event = AcademicEvent.new(academic_event_params)
    # Atribui a cor automaticamente baseada no tipo selecionado
    @academic_event.color = AcademicEvent::TYPES_AND_COLORS[@academic_event.event_type]

    if @academic_event.save
      redirect_to academic_events_path, notice: "Evento acadêmico criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @academic_event.assign_attributes(academic_event_params)
    @academic_event.color = AcademicEvent::TYPES_AND_COLORS[@academic_event.event_type]

    if @academic_event.update(academic_event_params)
      redirect_to academic_events_path, notice: "Evento atualizado!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @academic_event.destroy
    redirect_to academic_events_path, notice: "Evento removido."
  end

  private

  def set_academic_event
    @academic_event = AcademicEvent.find(params[:id])
  end

  def academic_event_params
    params.require(:academic_event).permit(:title, :event_date, :event_type)
  end

  # MÉTODO DE SEGURANÇA: Ajuste 'admin?' para o nome do campo que você usa no banco
  def authorize_admin!
    unless current_professor.admin?
      redirect_to root_path, alert: "Acesso restrito ao administrador geral."
    end
  end
end