// Página "Saiba mais" (saibamais.html): abas "Como funciona", animações e scroll suave.

// ===== BARRA DE NAVEGAÇÃO: efeito ao rolar + menu mobile =====
const barraPrincipal = document.getElementById('barraPrincipal');
const menuBtn = document.getElementById('menuBtn');

window.addEventListener('scroll', () => {
  barraPrincipal.classList.toggle('rolando', window.scrollY > 40);
});

menuBtn.addEventListener('click', () => {
  barraPrincipal.classList.toggle('aberto');
});

document.querySelectorAll('.nav-links a').forEach(link => {
  link.addEventListener('click', () => {
    barraPrincipal.classList.remove('aberto');
  });
});


// ===== ABAS COMO FUNCIONA =====
function trocarAba(botao, id) {
  // Atualiza botões
  document.querySelectorAll('.aba-btn').forEach(b => b.classList.remove('aba-ativa'));
  botao.classList.add('aba-ativa');

  // Esconde todos os conteúdos
  document.querySelectorAll('.como-conteudo').forEach(c => c.classList.add('oculto'));

  // Mostra o selecionado com animação
  const alvo = document.getElementById('aba-' + id);
  alvo.classList.remove('oculto');
  alvo.style.opacity = '0';
  alvo.style.transform = 'translateY(12px)';
  requestAnimationFrame(() => {
    alvo.style.transition = 'opacity 0.35s ease, transform 0.35s ease';
    alvo.style.opacity = '1';
    alvo.style.transform = 'translateY(0)';
  });
}


// ===== ANIMAÇÕES DE ENTRADA (Intersection Observer) =====
const observador = new IntersectionObserver((entradas) => {
  entradas.forEach(entrada => {
    if (entrada.isIntersecting) {
      entrada.target.style.opacity = '1';
      entrada.target.style.transform = 'translateY(0)';
      observador.unobserve(entrada.target); // Para de observar após animar
    }
  });
}, { threshold: 0.1 });

// Elementos que recebem animação de entrada
const seletoresAnimados = [
  '.missao-card',
  '.pcard',
  '.tec-card',
  '.diff-item',
  '.tl-card',
  '.equipe-card',
  '.passo',
];

document.querySelectorAll(seletoresAnimados.join(', ')).forEach((el, i) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(24px)';
  el.style.transition = `opacity 0.5s ease ${(i % 4) * 0.08}s, transform 0.5s ease ${(i % 4) * 0.08}s`;
  observador.observe(el);
});


// ===== ANIMAÇÃO DO FLUXO HERO =====
// Pulsa os nós do fluxo visual em sequência
const nosFluxo = document.querySelectorAll('.fluxo-no');
let noAtual = 0;

function pulsarNo() {
  nosFluxo.forEach(n => n.style.opacity = '0.5');
  nosFluxo[noAtual].style.opacity = '1';
  nosFluxo[noAtual].style.transition = 'opacity 0.4s ease';
  noAtual = (noAtual + 1) % nosFluxo.length;
}

if (nosFluxo.length) {
  pulsarNo();
  setInterval(pulsarNo, 1200);
}


// ===== SCROLL SUAVE PARA ÂNCORAS INTERNAS =====
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', (e) => {
    const alvo = document.querySelector(link.getAttribute('href'));
    if (alvo) {
      e.preventDefault();
      const topo = alvo.getBoundingClientRect().top + window.scrollY - 88;
      window.scrollTo({ top: topo, behavior: 'smooth' });
    }
  });
});


// ===== NAVEGAÇÃO =====
function abrirCadastro() {
  window.location.href = 'cadastro.html';
}

function abrirEntrar() {
  window.location.href = 'login.html';
}