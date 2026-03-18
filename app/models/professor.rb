class Professor < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # O login (Professor) tem um perfil pedagógico (Teacher)
  has_one :teacher, foreign_key: :user_id
  has_one :teacher, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_and_belongs_to_many :subjects
  enum :view_mode, { modo_professor: 0, modo_admin: 1 }, default: :modo_professor
end