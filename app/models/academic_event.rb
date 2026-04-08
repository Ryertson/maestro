# app/models/academic_event.rb
class AcademicEvent < ApplicationRecord
  # Validações básicas para evitar erros no calendário
  validates :title, :event_date, :event_type, :color, presence: true

  # Definição dos tipos e cores baseada no seu pedido
  # Isso facilita a criação do formulário e a lógica do calendário
  TYPES_AND_COLORS = {
    "Semana de Provas" => "#ff4d4d", # Vermelho
    "Feriado" => "#4a4a4a",          # Cinza Chumbo
    "Reunião de Pais" => "#fff9c4",  # Amarelo Claro
    "Outros" => "#e2e8f0"            # Cinza claro padrão
  }.freeze

  def self.event_types
    TYPES_AND_COLORS.keys
  end
end
