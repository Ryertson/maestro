module ApplicationHelper
  def status_color(status)
    case status
    when "pronto"
      "bg-green-100 text-green-700"
    when "preparando"
      "bg-amber-100 text-amber-700"
    else
      "bg-slate-100 text-slate-700"
    end
  end

  def status_color_helper(status)
    case status
    when 'Entregue' then '#198754'         # Verde
    when 'Atrasado' then '#ffc107'         # Amarelo/Laranja
    when 'Não Entregue' then '#dc3545'     # Vermelho
    else '#6c757d'                         # Cinza (Pendente)
    end
  end
end
