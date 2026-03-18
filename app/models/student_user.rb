class StudentUser < ApplicationRecord
  # Configurações padrão do Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  # O login pertence a um cadastro de aluno (Obrigatório para o vínculo funcionar)
  belongs_to :student

  # Validações para garantir integridade
  validates :student_id, presence: true, uniqueness: true

  # Callback para atualizar o registro do Aluno assim que o usuário for criado
  after_create :vincular_ao_perfil_do_aluno

  private

  # Método para gravar o ID do usuário de volta na tabela de Students
  def vincular_ao_perfil_do_aluno
    # Atualiza o campo student_user_id no modelo Student para manter a relação sincronizada
    student.update_column(:student_user_id, self.id) if student.present?
  end
end
