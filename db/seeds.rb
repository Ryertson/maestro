# Este arquivo limpa e popula os dados iniciais do Maestro 2026.
# Para executar, use o comando: rails db:seed

puts "Limpando registros antigos de Bimestres..."
Term.destroy_all

puts "Criando os 4 Bimestres para o ano letivo de 2026..."

Term.create!([
  { 
    name: "1º Bimestre", 
    start_date: "2026-02-02", 
    end_date: "2026-04-17", 
    color: "#6f42c1" # Roxo Translúcido (Identidade Maestro)
  },
  { 
    name: "2º Bimestre", 
    start_date: "2026-04-20", 
    end_date: "2026-06-26", 
    color: "#0d6efd" # Azul
  },
  { 
    name: "3º Bimestre", 
    start_date: "2026-08-03", 
    end_date: "2026-10-09", 
    color: "#198754" # Verde
  },
  { 
    name: "4º Bimestre", 
    start_date: "2026-10-13", 
    end_date: "2026-12-18", 
    color: "#fd7e14" # Laranja
  }
])

puts "✅ Sucesso! 4 Bimestres foram configurados e as cores estão prontas para o calendário."