module LessonsHelper
  def style_for_date(date)
    # Busca se a data pertence a algum bimestre cadastrado
    term = Term.for_date(date)
    return "" unless term

    # Converte Hex para RGB para aplicar transparência
    hex = term.color.gsub('#', '')
    rgb = hex.scan(/../).map { |color| color.hex }
    
    # Retorna o estilo com 0.15 de opacidade (Roxo Translúcido)
    "background-color: rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, 0.15); border: 1px solid rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, 0.3);"
  end

  # Helper para as cores do status da aula na tabela
  def status_color_bootstrap(status)
    case status
    when 'scheduled' then 'text-bg-info'
    when 'in_progress' then 'text-bg-warning'
    when 'completed' then 'text-bg-success'
    else 'text-bg-secondary'
    end
  end

  def current_term_class(term)
    "is-current-term" if Date.current.between?(term.start_date, term.end_date)
  end
end
