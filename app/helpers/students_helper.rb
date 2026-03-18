module StudentsHelper
  def attendance_icon(status)
    case status.to_s.downcase.strip
    when 'presente', 'present'
      'bi-check-lg'
    when 'faltou', 'absent'
      'bi-x-lg'
    when 'atrasado', 'late'
      'bi-clock'
    when 'justificada', 'justified'
      'bi-info-circle'
    else
      ''
    end
  end
end
