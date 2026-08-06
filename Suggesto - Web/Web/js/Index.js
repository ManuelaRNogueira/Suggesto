// ===== BARRA DE NAVEGAÇÃO: efeito ao rolar + menu mobile =====
const barraPrincipal = document.getElementById('barraPrincipal');
const menuBtn = document.getElementById('menuBtn');

window.addEventListener('scroll', () => {
  if (window.scrollY > 40) {
    barraPrincipal.classList.add('rolando');
  } else {
    barraPrincipal.classList.remove('rolando');
  }
});

menuBtn.addEventListener('click', () => {
  barraPrincipal.classList.toggle('aberto');
});

// Fechar menu ao clicar em qualquer link
document.querySelectorAll('.nav-links a').forEach(link => {
  link.addEventListener('click', () => {
    barraPrincipal.classList.remove('aberto');
  });
});


// ===== VITRINE (CAROUSEL) =====
const slides = document.querySelectorAll('.vitrine-slide');
const pontos = document.querySelectorAll('.ponto');
const setaProxima = document.getElementById('setaProxima');
const setaAnterior = document.getElementById('setaAnterior');
let slideAtual = 0;

function irParaSlide(indice) {
  // Remove destaque do slide e ponto atuais
  slides[slideAtual].classList.remove('vitrine-slide-ativo');
  pontos[slideAtual].classList.remove('ponto-ativo');

  // Calcula o próximo slide (volta ao início se passar do último)
  slideAtual = (indice + slides.length) % slides.length;

  // Ativa o novo slide e ponto
  slides[slideAtual].classList.add('vitrine-slide-ativo');
  pontos[slideAtual].classList.add('ponto-ativo');
}

setaProxima.addEventListener('click', () => irParaSlide(slideAtual + 1));
setaAnterior.addEventListener('click', () => irParaSlide(slideAtual - 1));

// Troca automática a cada 5 segundos
let temporizador = setInterval(() => irParaSlide(slideAtual + 1), 5000);

// Pausa ao passar o mouse na vitrine
const vitrine = document.querySelector('.vitrine');
vitrine.addEventListener('mouseenter', () => clearInterval(temporizador));
vitrine.addEventListener('mouseleave', () => {
  temporizador = setInterval(() => irParaSlide(slideAtual + 1), 5000);
});


// ===== ANIMAÇÕES DE ENTRADA =====
const observador = new IntersectionObserver((entradas) => {
  entradas.forEach(entrada => {
    if (entrada.isIntersecting) {
      entrada.target.style.opacity = '1';
      entrada.target.style.transform = 'translateY(0)';
    }
  });
}, { threshold: 0.1 });

// Aplica animação nos cards e caixas ao entrar na tela
document.querySelectorAll('.func-card, .papel-card, .caixa').forEach(elemento => {
  elemento.style.opacity = '0';
  elemento.style.transform = 'translateY(24px)';
  elemento.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
  observador.observe(elemento);
});


// ===== NAVEGAÇÃO =====
function abrirCadastro() {
  window.location.href = "cadastro.html";
}

function abrirEntrar() {
  window.location.href = "login.html";
}