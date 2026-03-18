class TeacherAssignment < ApplicationRecord
  belongs_to :teacher
  belongs_to :subject
  # Mudamos para optional: true para permitir salvar a matéria no perfil do professor
  belongs_to :classroom, optional: true
  belongs_to :course, optional: true
  

  before_validation :assign_course_from_classroom

  # Unicidade: só barra se for o MESMO professor, na MESMA turma, com a MESMA matéria
  validates :subject_id, uniqueness: { scope: [:teacher_id, :classroom_id], message: "já está vinculada a este perfil." }

  private

  def assign_course_from_classroom
    # Só tenta atribuir o curso se a turma estiver presente
    self.course = classroom.course if classroom.present?
  end
end