class Term < ApplicationRecord
  validates :name, :start_date, :end_date, :color, presence: true

  # Método para contar dias úteis (Segunda a Sexta)
  def work_days
    return 0 unless start_date && end_date
    (start_date..end_date).count { |day| (1..5).include?(day.wday) }
  end

  # Encontra qual bimestre corresponde a uma data específica
  def self.for_date(date)
    return nil if date.nil?
    find_by("start_date <= ? AND end_date >= ?", date, date)
  end
end
