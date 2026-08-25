// ===== BARRA DE NAVEGAÇÃO =====
const barraPrincipal = document.getElementById('barraPrincipal');
const menuBtn = document.getElementById('menuBtn');

window.addEventListener('scroll', () => {
  barraPrincipal.classList.toggle('rolando', window.scrollY > 40);
});

menuBtn.addEventListener('click', () => {
  barraPrincipal.classList.toggle('aberto');
});

document.querySelectorAll('.nav-links a').forEach(link => {
  link.addEventListener('click', () => barraPrincipal.classList.remove('aberto'));
});


// ===== TOGGLE MENSAL / ANUAL =====
const toggleBtn = document.getElementById('toggleBtn');
const labelMensal = document.getElementById('labelMensal');
const labelAnual = document.getElementById('labelAnual');

// Preços mensais e anuais de cada plano
const precos = {
  basico:      { mensal: 49,  anual: 39  },
  pro:         { mensal: 119, anual: 95  },
  empresarial: { mensal: 299, anual: 239 },
};

let periodoAnual = false;

function alternarPeriodo() {
  periodoAnual = !periodoAnual;

  // Atualiza visual do toggle
  toggleBtn.classList.toggle('ativo', periodoAnual);
  labelMensal.classList.toggle('ativo', !periodoAnual);
  labelAnual.classList.toggle('ativo', periodoAnual);

  // Atualiza os preços exibidos
  for (const [plano, valores] of Object.entries(precos)) {
    const elementoPreco = document.getElementById(`preco-${plano}`);
    const elementoAnual = document.getElementById(`anual-${plano}`);

    if (elementoPreco) {
      elementoPreco.textContent = periodoAnual ? valores.anual : valores.mensal;
    }

    if (elementoAnual) {
      elementoAnual.classList.toggle('visivel', periodoAnual);
    }
  }
}

// Inicializa label mensal como ativo
labelMensal.classList.add('ativo');


// ===== FAQ: abrir e fechar perguntas =====
function abrirFaq(item) {
  const jaEstaAberto = item.classList.contains('aberto');

  // Fecha todos os itens
  document.querySelectorAll('.faq-item').forEach(faq => faq.classList.remove('aberto'));

  // Se o clicado não estava aberto, abre ele
  if (!jaEstaAberto) {
    item.classList.add('aberto');
  }
}


// ===== ANIMAÇÕES DE ENTRADA =====
const observador = new IntersectionObserver((entradas) => {
  entradas.forEach(entrada => {
    if (entrada.isIntersecting) {
      entrada.target.style.opacity = '1';
      entrada.target.style.transform = 'translateY(0)';
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.plano-card, .faq-item').forEach((elemento, indice) => {
  elemento.style.opacity = '0';
  elemento.style.transform = 'translateY(24px)';
  elemento.style.transition = `opacity 0.5s ease ${indice * 0.1}s, transform 0.5s ease ${indice * 0.1}s`;
  observador.observe(elemento);
});


// ===== NAVEGAÇÃO =====
function assinarPlano(nomePlano) {
  sessionStorage.setItem("planoEscolhido", nomePlano);
  sessionStorage.setItem("periodoEscolhido", periodoAnual ? "anual" : "mensal");
  window.location.href = "pagamento.html";
}

function abrirCadastroAdm() {
  window.location.href = "cadastroAdm.html";
}
function abrirCadastro() {
  window.location.href = "cadastro.html";
}

function abrirEntrar() {
  window.location.href = "login.html";
}