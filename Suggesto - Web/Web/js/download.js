// Página de download do app desktop (download.html). O login aqui é só visual
// (simulado), não chama a API.

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


// ===== MOSTRAR / OCULTAR SENHA =====
function alternarSenha() {
  const campoSenha = document.getElementById('campoSenha');
  const iconeOlho  = document.getElementById('iconeOlho');

  if (campoSenha.type === 'password') {
    campoSenha.type = 'text';
    iconeOlho.classList.replace('fa-eye', 'fa-eye-slash');
  } else {
    campoSenha.type = 'password';
    iconeOlho.classList.replace('fa-eye-slash', 'fa-eye');
  }
}


// ===== VERIFICAÇÃO DE ACESSO =====
function verificarAcesso() {
  const email = document.getElementById('campoEmail').value.trim();
  const senha  = document.getElementById('campoSenha').value.trim();
  const erroLogin      = document.getElementById('erroLogin');
  const mensagemErro   = document.getElementById('mensagemErro');
  const etapaBotao     = document.querySelector('.etapa-btn');

  // Validação dos campos
  if (!email || !senha) {
    mensagemErro.textContent = 'Por favor, preencha todos os campos.';
    erroLogin.classList.add('visivel');
    return;
  }

  if (!email.includes('@')) {
    mensagemErro.textContent = 'Informe um e-mail válido.';
    erroLogin.classList.add('visivel');
    return;
  }

  // Esconde erro anterior
  erroLogin.classList.remove('visivel');

  // Simula carregamento (aqui você vai conectar com o backend depois)
  etapaBotao.disabled = true;
  etapaBotao.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Verificando...';

  setTimeout(() => {
  mostrarDownload();
}, 1500);
}

// Permite pressionar Enter para verificar
document.getElementById('campoSenha').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') verificarAcesso();
});
document.getElementById('campoEmail').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') verificarAcesso();
});


// ===== EXIBE A TELA DE DOWNLOAD =====
function mostrarDownload() {
  document.getElementById('etapaLogin').classList.add('etapa-oculta');
  document.getElementById('etapaDownload').classList.remove('etapa-oculta');
}


// ===== VOLTAR PARA LOGIN =====
function sairDownload() {
  document.getElementById('etapaDownload').classList.add('etapa-oculta');
  document.getElementById('etapaLogin').classList.remove('etapa-oculta');

  // Limpa os campos
  document.getElementById('campoEmail').value = '';
  document.getElementById('campoSenha').value = '';
  document.getElementById('erroLogin').classList.remove('visivel');

  const etapaBotao = document.querySelector('.etapa-btn');
  etapaBotao.disabled = false;
  etapaBotao.innerHTML = 'Verificar acesso <i class="fas fa-arrow-right"></i>';

  // Esconde progresso se estava visível
  document.getElementById('downloadProgresso').classList.remove('visivel');
}


// ===== SIMULA PROGRESSO DE DOWNLOAD =====
function iniciarDownload(sistema) {
  const progresso      = document.getElementById('downloadProgresso');
  const progressoBarra = document.getElementById('progressoBarra');
  const progressoNome  = document.getElementById('progressoNome');
  const progressoPercent = document.getElementById('progressoPercent');
  const progressoInfo  = document.getElementById('progressoInfo');

  // Define o nome do arquivo conforme o sistema
  const nomeArquivo = sistema === 'windows' ? 'Suggesto-Setup-1.0.0.exe' : 'Suggesto-1.0.0.dmg';

  progressoNome.textContent    = nomeArquivo;
  progressoBarra.style.width   = '0%';
  progressoPercent.textContent = '0%';
  progressoInfo.textContent    = 'Preparando download...';
  progresso.classList.add('visivel');

  // Rolagem suave até a barra de progresso
  progresso.scrollIntoView({ behavior: 'smooth', block: 'center' });


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

document.querySelectorAll('.app-func-item, .passo').forEach((elemento, indice) => {
  elemento.style.opacity = '0';
  elemento.style.transform = 'translateY(24px)';
  elemento.style.transition = `opacity 0.5s ease ${indice * 0.08}s, transform 0.5s ease ${indice * 0.08}s`;
  observador.observe(elemento);
});


// ===== NAVEGAÇÃO =====
function abrirCadastro() {
  window.location.href = 'cadastro.html';
}

function abrirEntrar() {
  window.location.href = 'login.html';
}