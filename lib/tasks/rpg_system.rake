namespace :rpg do
  desc "Gera XP retroativo para todos os alunos com base nas notas já cadastradas"
  task migrate_retroactive_xp: :environment do
    puts "--- [MAESTRO] Iniciando Sincronização de XP Retroativo ---"
    
    Student.find_each do |student|
      # 1. Soma todos os pontos que o aluno já tem no banco (atividades passadas)
      total_points_in_db = student.student_points.sum(:points).to_f
      
      # 2. Calcula quanto de XP total ele deveria ter (Regra: 1 ponto = 10 XP)
      expected_total_xp = (total_points_in_db * 10).to_i
      
      # 3. Verifica quanto ele já tem registrado para não duplicar
      current_total_xp = student.total_xp || 0
      xp_to_add = expected_total_xp - current_total_xp

      if xp_to_add > 0
        puts ">> Processando #{student.name}: +#{xp_to_add} XP adicionados."
        student.gain_xp(xp_to_add)
      else
        puts "-- #{student.name}: XP já está em dia."
      end
    end

    puts "--- [MAESTRO] Sincronização Concluída! ---"
  end
end