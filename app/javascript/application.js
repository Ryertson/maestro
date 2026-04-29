// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Função para limpar o cabeçalho "teimoso" do FullCalendar
const cleanCalendarHeader = () => {
  const elementsToRemove = [
    '.fc-header-toolbar',
    '.fc-toolbar',
    '.fc-toolbar-title',
    '.fc-button-group',
    '.fc-today-button'
  ];

  elementsToRemove.forEach(selector => {
    document.querySelectorAll(selector).forEach(el => {
      el.style.display = 'none';
      el.style.visibility = 'hidden';
      el.remove(); // Remove do DOM para garantir
    });
  });
};

document.addEventListener("turbo:load", function() {
  // --- LÓGICA DA SIDEBAR ---
  const hamburger = document.querySelector(".toggle-btn");
  const sidebar = document.querySelector("#sidebar");

  if (hamburger && sidebar) {
    hamburger.onclick = function() {
      sidebar.classList.toggle("expand");
      
      const icon = hamburger.querySelector("i");
      
      if (sidebar.classList.contains("expand")) {
        icon.classList.replace("bx-chevrons-right", "bx-chevrons-left");
      } else {
        icon.classList.replace("bx-chevrons-left", "bx-chevrons-right");
      }
    };
  }

  // --- LÓGICA DO CALENDÁRIO ---
  // Executa a limpeza imediatamente
  cleanCalendarHeader();

  // Caso o FullCalendar demore um pouco para renderizar, tentamos novamente após 100ms
  setTimeout(cleanCalendarHeader, 100);
});

// Garante que a limpeza ocorra também em mudanças de visualização do calendário
document.addEventListener("click", function(e) {
  if (e.target.closest('.fc-button') || e.target.closest('.btn')) {
    setTimeout(cleanCalendarHeader, 50);
  }
});