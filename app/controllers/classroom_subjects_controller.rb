# app/controllers/classroom_subjects_controller.rb
class ClassroomSubjectsController < ApplicationController
  before_action :set_classroom

  def index
    @classroom_subjects = @classroom.classroom_subjects.includes(:subject, :teacher)
    # Disciplinas que ainda não estão nesta turma
    @available_subjects = Subject.where.not(id: @classroom.subjects.pluck(:id))
    @classroom_subject = ClassroomSubject.new
  end

  def create
    @classroom_subject = @classroom.classroom_subjects.build(classroom_subject_params)
    if @classroom_subject.save
      redirect_to classroom_subjects_path(classroom_id: @classroom.id), notice: "Disciplina vinculada!"
    else
      redirect_to classroom_subjects_path(classroom_id: @classroom.id), alert: "Erro ao vincular."
    end
  end

  def destroy
    @classroom_subject = ClassroomSubject.find(params[:id])
    @classroom_subject.destroy
    redirect_to classroom_subjects_path(classroom_id: @classroom.id), notice: "Vínculo removido."
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def classroom_subject_params
    params.require(:classroom_subject).permit(:subject_id, :teacher_id)
  end
end