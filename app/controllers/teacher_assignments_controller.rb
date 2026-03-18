class TeacherAssignmentsController < ApplicationController
  def create
    @teacher = Teacher.find(params[:teacher_id])
    @assignment = @teacher.teacher_assignments.build(assignment_params)

    if @assignment.save
      redirect_to @teacher, notice: "Professor vinculado com sucesso!"
    else
      redirect_to @teacher, alert: "Erro real: #{@assignment.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @assignment = TeacherAssignment.find(params[:id])
    @teacher = @assignment.teacher
    @assignment.destroy
    redirect_to @teacher, notice: "Atribuição removida."
  end

  private

  def assignment_params
    params.require(:teacher_assignment).permit(:classroom_id)
  end
end
