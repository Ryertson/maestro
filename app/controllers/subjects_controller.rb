class SubjectsController < ApplicationController
  def create
    @subject = Subject.new(subject_params)
    if @subject.save
      redirect_to academic_settings_path, notice: "Disciplina '#{@subject.name}' adicionada!"
    else
      redirect_to academic_settings_path, alert: "Erro ao adicionar disciplina: #{@subject.errors.full_messages.to_sentence}"
    end
  end

  private

  def subject_params
    params.require(:subject).permit(:name, :knowledge_area_id)
  end
end