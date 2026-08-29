const API_BASE = window.API_BASE;

function obterIdUsuario() {
  const raw = localStorage.getItem("idUsuario") ?? sessionStorage.getItem("idUsuario");
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

// Todo card desta página já está salvo, então o favorito nasce sempre
// preenchido/ativo — clicar nele abre o mesmo modal de confirmação que já
// existia (ver removerComConfirmacao / confirmarRemover).
const opcoesCardSalvo = {
  verificarSalvo: () => true,
  aoClicarFavorito: removerComConfirmacao,
};

function removerComConfirmacao(idEstab, btn) {
  const card = btn.closest('.local-card');
  if (card) confirmarRemover(card);
}

document.addEventListener('DOMContentLoaded', () => {
  const idUsuario = localStorage.getItem('idUsuario');
  if (!idUsuario) {
    window.location.href = 'login.html';
    return;
  }

  carregarDadosUsuario();
  carregarLocaisSalvos();
});

function carregarDadosUsuario() {
  const nomeCompleto = localStorage.getItem('nomeUsuario') || 'Cliente';
  const idUsuario = obterIdUsuario();

  const partes = nomeCompleto.split(' ');
  let iniciais = partes[0].charAt(0).toUpperCase();
  if (partes.length > 1) {
    iniciais += partes[partes.length - 1].charAt(0).toUpperCase();
  }

  const elNome = document.getElementById('sidebarNome');
  const elAvatar = document.getElementById('sidebarAvatar');
  if (elNome) elNome.innerText = nomeCompleto;
  if (elAvatar) elAvatar.innerText = iniciais;

  // Busca a foto de perfil de verdade — só troca as iniciais se existir.
  if (idUsuario) {
    fetch(`${API_BASE}/usuarios/${idUsuario}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((usuario) => {
        const urlFoto = resolverUrlFotoUsuario(usuario?.fotoUrl);
        if (urlFoto && elAvatar) {
          elAvatar.innerHTML = `<img src="${urlFoto}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;display:block;">`;
        }
      })
      .catch(() => {});
  }
}

// Mesma lógica usada pra foto de estabelecimento (ver js/localCard.js), sem
// placeholder — avatar sem foto mostra iniciais, não uma imagem substituta.
function resolverUrlFotoUsuario(fotoUrl) {
  const nome = fotoUrl ? String(fotoUrl).trim() : "";
  if (!nome) return "";
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${API_BASE.replace("/api", "")}/uploads/${relativo}`;
}

async function carregarLocaisSalvos() {
  const grade = document.getElementById('locaisGrade');
  const vazio = document.getElementById('locaisVazio');
  const idUsuario = localStorage.getItem('idUsuario');

  if (!grade || !idUsuario) return;

  try {
    const resposta = await fetch(`${API_BASE}/locais-salvos/usuario/${idUsuario}`);

    if (!resposta.ok) {
      throw new Error('Erro ao buscar locais salvos.');
    }

    const estabelecimentos = await resposta.json();
    grade.innerHTML = '';

    if (!estabelecimentos.length) {
      vazio?.classList.add('visivel');
      atualizarContador();
      return;
    }

    vazio?.classList.remove('visivel');

    estabelecimentos.forEach(estab => {
      const card = criarCardSalvo(estab);
      if (!card.dataset.estabelecimentoId) {
        console.warn('Estabelecimento sem ID válido — remoção pode falhar:', estab);
      }
      grade.appendChild(card);
    });

    atualizarContador();
  } catch (error) {
    console.error('Erro ao carregar locais salvos:', error);
    grade.innerHTML = `
      <p style="color: white; text-align: center; grid-column: 1/-1;">
        Não foi possível carregar seus locais salvos.
      </p>
    `;
  }
}

function criarCardSalvo(estab) {
  return criarCardEstabelecimento(estab, opcoesCardSalvo);
}

function filtrarLocais() {
  const busca = document.getElementById('campoBusca').value.toLowerCase();
  const cards = document.querySelectorAll('#locaisGrade .local-card');
  const vazio = document.getElementById('locaisVazio');
  let visiveis = 0;

  cards.forEach(card => {
    const nome = card.querySelector('.local-nome').textContent.toLowerCase();
    const endereco = card.querySelector('.local-endereco').textContent.toLowerCase();
    const visivel = nome.includes(busca) || endereco.includes(busca);
    card.style.display = visivel ? '' : 'none';
    if (visivel) visiveis++;
  });

  vazio.classList.toggle('visivel', visiveis === 0 && cards.length > 0);
  atualizarContador();
}

function filtrarCategoria(botao, categoria) {
  document.querySelectorAll('.filtro-chip').forEach(b => b.classList.remove('filtro-chip-ativo'));
  botao.classList.add('filtro-chip-ativo');

  const cards = document.querySelectorAll('#locaisGrade .local-card');
  const vazio = document.getElementById('locaisVazio');
  let visiveis = 0;

  cards.forEach(card => {
    const cat = card.dataset.categoria;
    const visivel = categoria === 'todos' || cat === categoria;
    card.style.display = visivel ? '' : 'none';
    if (visivel) visiveis++;
  });

  vazio.classList.toggle('visivel', visiveis === 0 && cards.length > 0);
  atualizarContador();
}

function limparFiltros() {
  document.getElementById('campoBusca').value = '';
  const chips = document.querySelectorAll('.filtro-chip');
  chips.forEach(c => c.classList.remove('filtro-chip-ativo'));
  chips[0].classList.add('filtro-chip-ativo');

  document.querySelectorAll('#locaisGrade .local-card').forEach(c => c.style.display = '');
  document.getElementById('locaisVazio').classList.remove('visivel');
  atualizarContador();
}

function ordenarLocais() {
  const criterio = document.getElementById('selectOrdenacao').value;
  const grade = document.getElementById('locaisGrade');
  const cards = Array.from(grade.querySelectorAll('.local-card'));

  cards.sort((a, b) => {
    if (criterio === 'nome') {
      return a.dataset.nome.localeCompare(b.dataset.nome);
    }
    return 0;
  });

  cards.forEach(card => grade.appendChild(card));
}

let cardParaRemover = null;

function confirmarRemover(card) {
  cardParaRemover = card;
  const nome = card.querySelector('.local-nome').textContent;
  document.getElementById('modalRemoverNome').textContent =
    `"${nome}" será removido da sua lista de salvos.`;

  abrirModal('modalRemover');

  document.getElementById('btnConfirmarRemover').onclick = async () => {
    if (!cardParaRemover) return;

    const usuarioId = obterIdUsuario();
    const estabelecimentoId = Number(cardParaRemover.dataset.estabelecimentoId);
    const nomeLocal = cardParaRemover.querySelector('.local-nome').textContent;

    console.log("Usuario:", usuarioId, "Estabelecimento:", estabelecimentoId);

    if (!usuarioId || !Number.isFinite(estabelecimentoId) || estabelecimentoId <= 0) {
      mostrarToast('Não foi possível identificar o local para remover.');
      return;
    }

    try {
      const resposta = await fetch(
        `${API_BASE}/locais-salvos/${usuarioId}/${estabelecimentoId}`,
        { method: 'DELETE' }
      );

      if (!resposta.ok) throw new Error('Erro ao remover local salvo.');

      cardParaRemover.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
      cardParaRemover.style.opacity = '0';
      cardParaRemover.style.transform = 'scale(0.95)';

      setTimeout(() => {
        cardParaRemover.remove();
        cardParaRemover = null;
        fecharModal('modalRemover');
        atualizarContador();
        mostrarToast(`"${nomeLocal}" removido dos salvos.`);

        const cards = document.querySelectorAll('#locaisGrade .local-card');
        if (cards.length === 0) {
          document.getElementById('locaisVazio').classList.add('visivel');
        }
      }, 300);
    } catch (error) {
      console.error('Erro ao remover local salvo:', error);
      mostrarToast('Não foi possível remover o local.');
    }
  };
}

function atualizarContador() {
  const total = document.querySelectorAll('#locaisGrade .local-card').length;
  const el = document.getElementById('totalSalvos');
  if (el) el.textContent = total;
}

function abrirSugestaoLocal(nomeLocal) {
  document.getElementById('modalLocalNome').textContent = nomeLocal;
  abrirModal('modalSugestao');
}

function enviarSugestao() {
  const textarea = document.querySelector('#modalSugestao .campo-textarea');
  if (!textarea.value.trim()) {
    textarea.style.borderColor = 'rgba(239,68,68,0.5)';
    setTimeout(() => textarea.style.borderColor = '', 1500);
    return;
  }
  fecharModal('modalSugestao');
  textarea.value = '';
  mostrarToast('Sugestão enviada com sucesso!');
}

function abrirModal(id) {
  document.getElementById(id).classList.add('aberto');
}

function fecharModal(id) {
  document.getElementById(id).classList.remove('aberto');
  document.getElementById(id).style.display = '';
}

document.querySelectorAll('.modal-fundo').forEach(fundo => {
  fundo.addEventListener('click', (e) => {
    if (e.target === fundo) fundo.classList.remove('aberto');
  });
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-fundo').forEach(m => m.classList.remove('aberto'));
  }
});

function abrirModalSair() {
  abrirModal('modalSair');
}

function confirmarSair() {
  localStorage.clear();
  sessionStorage.clear();
  window.location.href = 'login.html';
}

let toastTimeout;

function mostrarToast(mensagem) {
  clearTimeout(toastTimeout);
  const toast = document.getElementById('toast');
  document.getElementById('toastMsg').textContent = mensagem;
  toast.classList.add('visivel');
  toastTimeout = setTimeout(() => toast.classList.remove('visivel'), 3000);
}
