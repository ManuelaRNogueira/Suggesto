// Página pública "Para empresas" (adms.html): menu, animações e links de navegação.

// ===== NAVBAR: scroll + menu mobile =====
const navbar = document.getElementById('barraPrincipal');
const menuBtn = document.getElementById('menuBtn');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('rolando', window.scrollY > 40);
});

menuBtn.addEventListener('click', () => {
  navbar.classList.toggle('aberto');
});

document.querySelectorAll('.nav-links a').forEach(link => {
  link.addEventListener('click', () => navbar.classList.remove('aberto'));
});


// ===== ANIMAÇÕES DE ENTRADA =====
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visivel');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.animavel').forEach((el, i) => {
  el.style.transitionDelay = `${(i % 4) * 0.07}s`;
  observer.observe(el);
});


// ===== SCROLL SUAVE PARA ÂNCORAS =====
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', (e) => {
    const alvo = document.querySelector(link.getAttribute('href'));
    if (alvo) {
      e.preventDefault();
      window.scrollTo({ top: alvo.getBoundingClientRect().top + window.scrollY - 88, behavior: 'smooth' });
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