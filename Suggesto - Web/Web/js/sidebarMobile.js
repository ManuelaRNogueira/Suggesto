// Abre/fecha o menu lateral como uma gaveta no mobile — compartilhado por
// todas as páginas com <aside class="sidebar">, <button id="sidebarToggle">
// e <div id="sidebarBackdrop">.
(function () {
  const sidebar = document.querySelector('.sidebar');
  const botao = document.getElementById('sidebarToggle');
  const fundo = document.getElementById('sidebarBackdrop');
  if (!sidebar || !botao || !fundo) return;

  function abrir() {
    sidebar.classList.add('aberto');
    fundo.classList.add('aberto');
    document.body.style.overflow = 'hidden';
  }

  function fechar() {
    sidebar.classList.remove('aberto');
    fundo.classList.remove('aberto');
    document.body.style.overflow = '';
  }

  botao.addEventListener('click', () => {
    sidebar.classList.contains('aberto') ? fechar() : abrir();
  });

  fundo.addEventListener('click', fechar);

  sidebar.querySelectorAll('a.nav-item').forEach((link) => {
    link.addEventListener('click', fechar);
  });
})();
