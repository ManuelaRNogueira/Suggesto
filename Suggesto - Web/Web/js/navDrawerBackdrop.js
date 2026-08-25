// Fundo escurecido atrás da gaveta do menu mobile (barra-nav.aberto) —
// clicar fora ou num link fecha o menu. Mesmo comportamento do menu lateral
// do painel (js/sidebarMobile.js), só que criado aqui via JS porque essas
// páginas públicas não têm um elemento de fundo fixo no HTML.
(function () {
  const nav = document.querySelector('.barra-nav');
  const botao = document.getElementById('menuBtn');
  if (!nav || !botao) return;

  const fundo = document.createElement('div');
  fundo.className = 'nav-drawer-backdrop';
  document.body.appendChild(fundo);

  function sincronizar() {
    fundo.classList.toggle('aberto', nav.classList.contains('aberto'));
  }

  // Roda depois do listener que a própria página já tem no botão (o que
  // faz o toggle da classe "aberto"), por isso o pequeno atraso.
  botao.addEventListener('click', () => setTimeout(sincronizar, 0));

  fundo.addEventListener('click', () => {
    nav.classList.remove('aberto');
    sincronizar();
  });

  nav.querySelectorAll('.nav-links a').forEach((link) => {
    link.addEventListener('click', () => {
      nav.classList.remove('aberto');
      sincronizar();
    });
  });
})();
