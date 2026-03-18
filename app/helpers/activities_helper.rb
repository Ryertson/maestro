module ActivitiesHelper
  def status_class(status)
    case status
    when 'Pendente'      then 'bg-secondary'
    when 'Entregue'      then 'bg-success'
    when 'Não Entregue'  then 'bg-danger'
    else 'bg-dark'
    end
  end
end
