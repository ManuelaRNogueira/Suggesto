// Protege as páginas que exigem login. Roda antes de tudo, no <head>, pra
// barrar duas formas de acessar a página sem estar logado:
//   1) digitando o endereço direto na barra do navegador;
//   2) usando voltar/avançar do navegador depois de sair da conta — nesse
//      caso o navegador pode restaurar a página do cache (bfcache) sem
//      rodar os scripts de novo, então também escutamos o evento
//      "pageshow" pra checar de novo quando isso acontece.
(function () {
  function estaLogado() {
    return !!localStorage.getItem('idUsuario');
  }

  function protegerPagina() {
    if (!estaLogado()) {
      location.replace('login.html');
    }
  }

  protegerPagina();

  window.addEventListener('pageshow', function (evento) {
    if (evento.persisted) {
      protegerPagina();
    }
  });
})();
