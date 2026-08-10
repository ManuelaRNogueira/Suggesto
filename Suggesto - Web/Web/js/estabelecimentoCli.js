const API_BASE = "http://localhost:8080/api";

let est = null;        // dados reais do estabelecimento carregado da API
let avaliacoes = [];    // avaliações reais do estabelecimento
let salvo = false;
let filtroAtivo = 'todas';


// ── INICIALIZA ────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  carregarDadosUsuario();

  const id = obterIdEstabelecimento();
  if (!id) {
    mostrarErroCarregamento();
    return;
  }

  await carregarEstabelecimento(id);
  if (est) {
    await carregarAvaliacoes(id);
    verificarSeFavorito();
  }
});

function obterIdEstabelecimento() {
  const params = new URLSearchParams(window.location.search);
  const id = Number(params.get('id'));
  return Number.isFinite(id) && id > 0 ? id : null;
}

function urlFotoEstabelecimento(fotoPath) {
  if (!fotoPath) return '';
  if (/^https?:\/\//i.test(fotoPath)) return fotoPath;
  return `http://localhost:8080/uploads/${fotoPath}`;
}

function montarEndereco(dados) {
  const partes = [
    [dados.rua, dados.numero].filter(Boolean).join(', '),
    dados.complemento,
    dados.bairro,
    [dados.cidade, dados.estado].filter(Boolean).join(' - '),
  ].filter(p => p && String(p).trim());
  return partes.join(', ');
}

function escapeHtml(texto) {
  const div = document.createElement('div');
  div.textContent = texto ?? '';
  return div.innerHTML;
}


// ── CARREGAR NOME DO USUÁRIO ─────────────────────────────────────────
function carregarDadosUsuario() {
  const nomeCompleto = localStorage.getItem('nomeUsuario') || 'Cliente';
  const partes = nomeCompleto.split(' ');
  let iniciais = partes[0].charAt(0).toUpperCase();
  if (partes.length > 1) iniciais += partes[partes.length - 1].charAt(0).toUpperCase();

  const elNome = document.getElementById('sidebarNome');
  const elAvatar = document.getElementById('sidebarAvatar');
  if (elNome) elNome.innerText = nomeCompleto;
  if (elAvatar) elAvatar.innerText = iniciais;
}


// ── CARREGAR ESTABELECIMENTO REAL ──────────────────────────────────────
async function carregarEstabelecimento(id) {
  try {
    const resposta = await fetch(`${API_BASE}/estabelecimentos/${id}`);
    if (!resposta.ok) throw new Error('Estabelecimento não encontrado.');
    const dados = await resposta.json();

    est = {
      id: dados.idEstabelecimento,
      nome: dados.nome || 'Estabelecimento',
      categoria: dados.categoria || '—',
      telefone: dados.telefone || '',
      endereco: montarEndereco(dados),
      horario: dados.horarioFuncionamento || '',
      logo: urlFotoEstabelecimento(dados.fotoPath),
    };

    preencherHeader();
    verificarStatus();
  } catch (erro) {
    console.error('Erro ao carregar estabelecimento:', erro);
    mostrarErroCarregamento();
  }
}

function mostrarErroCarregamento() {
  document.getElementById('nomeEstab').textContent = 'Estabelecimento não encontrado';
  document.getElementById('categoriaEstab').textContent = '—';
  document.getElementById('enderecoCurto').textContent = '—';
  document.getElementById('notaEstab').textContent = '—';
  document.getElementById('totalAvaliacoes').textContent = '(0)';
  document.getElementById('resumoNota').textContent = '—';
  document.getElementById('resumoTotal').textContent = '0 avaliações';
  document.getElementById('resumoEstrelas').innerHTML = '';
  document.getElementById('resumoBarras').innerHTML = '';
  document.getElementById('listaSugestoes').innerHTML = '';
  document.getElementById('vazio').style.display = 'flex';
  document.getElementById('statusTexto').textContent = 'Indisponível';
  document.getElementById('statusDot').className = 'status-dot status-fechado';
  document.getElementById('statusHora').textContent = '';
  mostrarToast('Não foi possível carregar este estabelecimento.', 'erro');
}


// ── PREENCHER HEADER ─────────────────────────────────────────────────
function preencherHeader() {
  document.title = `${est.nome} — Suggesto`;

  document.getElementById('nomeEstab').textContent      = est.nome;
  document.getElementById('categoriaEstab').textContent = est.categoria;
  document.getElementById('enderecoCurto').textContent  = est.endereco
    ? est.endereco.split(',').slice(-2).join(',').trim()
    : 'Endereço não informado';
  document.getElementById('enderecoCompleto').textContent = est.endereco || 'Endereço não informado';
  document.getElementById('horarioEstab').textContent    = est.horario || 'Horário não informado';
  document.getElementById('telefoneEstab').textContent   = est.telefone || 'Não informado';
  document.getElementById('modalNomeEstab').textContent  = est.nome;

  const itemTelefone = document.getElementById('itemTelefone');
  if (itemTelefone) itemTelefone.style.cursor = est.telefone ? 'pointer' : 'default';

  // Logo
  const logo = document.getElementById('logoEstab');
  const placeholder = document.getElementById('logoPlaceholder');
  if (est.logo) {
    logo.src = est.logo;
    logo.style.display = '';
    placeholder.style.display = 'none';
  } else {
    logo.style.display = 'none';
    placeholder.style.display = 'flex';
  }
}


// ── VERIFICAR STATUS ABERTO/FECHADO ──────────────────────────────────
function verificarStatus() {
  const dot   = document.getElementById('statusDot');
  const texto = document.getElementById('statusTexto');
  const hora  = document.getElementById('statusHora');

  const status = calcularStatusEstabelecimento(est.horario);

  dot.className     = `status-dot ${status.aberto ? 'status-aberto' : 'status-fechado'}`;
  texto.textContent = status.label;
  texto.className   = `status-texto${status.aberto ? '' : ' fechado'}`;
  hora.textContent  = status.detalhe;
}


// ── CARREGAR AVALIAÇÕES REAIS ──────────────────────────────────────────
async function carregarAvaliacoes(id) {
  try {
    const resposta = await fetch(`${API_BASE}/avaliacoes/estabelecimento/${id}`);
    if (!resposta.ok) throw new Error('Erro ao buscar avaliações.');
    const dados = await resposta.json();
    avaliacoes = Array.isArray(dados) ? dados : [];
  } catch (erro) {
    console.error('Erro ao carregar avaliações:', erro);
    avaliacoes = [];
  }

  popularFiltros();
  renderizarResumo();
  renderizarSugestoes();
}

function popularFiltros() {
  const barra = document.getElementById('filtrosCategoria');
  if (!barra) return;

  const categorias = [...new Set(
    avaliacoes.map(a => a.categoria && a.categoria.nomeCategoria).filter(Boolean)
  )];

  barra.innerHTML = '<button class="filtro ativo" onclick="filtrar(this, \'todas\')">Todas</button>' +
    categorias.map(c => `<button class="filtro" onclick="filtrar(this, '${c.replace(/'/g, "\\'")}')">${escapeHtml(c)}</button>`).join('');

  filtroAtivo = 'todas';
}


// ── RESUMO DE AVALIAÇÃO (calculado a partir das avaliações reais) ─────
function renderizarResumo() {
  const total = avaliacoes.length;
  const soma = avaliacoes.reduce((acc, a) => acc + (Number(a.nota) || 0), 0);
  const media = total > 0 ? soma / total : 0;
  const mediaTexto = total > 0 ? media.toFixed(1) : '—';

  document.getElementById('notaEstab').textContent       = mediaTexto;
  document.getElementById('totalAvaliacoes').textContent = `(${total})`;
  document.getElementById('resumoNota').textContent      = mediaTexto;
  document.getElementById('resumoTotal').textContent     = `${total} ${total === 1 ? 'avaliação' : 'avaliações'}`;

  const el = document.getElementById('resumoEstrelas');
  el.innerHTML = '';
  for (let i = 1; i <= 5; i++) {
    const star = document.createElement('i');
    star.className = i <= Math.round(media) ? 'fas fa-star' : 'fas fa-star vazia';
    el.appendChild(star);
  }

  const dist = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  avaliacoes.forEach(a => {
    const nota = Math.round(Number(a.nota));
    if (dist[nota] !== undefined) dist[nota]++;
  });

  const barrasEl = document.getElementById('resumoBarras');
  barrasEl.innerHTML = '';
  for (let i = 5; i >= 1; i--) {
    const pct = total > 0 ? Math.round((dist[i] / total) * 100) : 0;
    barrasEl.innerHTML += `
      <div class="barra-linha">
        <span class="barra-label">${i}</span>
        <div class="barra-track">
          <div class="barra-fill" style="width:${pct}%"></div>
        </div>
        <span class="barra-qtd">${dist[i]}</span>
      </div>`;
  }
}


// ── RENDERIZAR SUGESTÕES/AVALIAÇÕES REAIS ──────────────────────────────
function renderizarSugestoes() {
  const lista = document.getElementById('listaSugestoes');
  const vazio = document.getElementById('vazio');

  const filtradas = filtroAtivo === 'todas'
    ? avaliacoes
    : avaliacoes.filter(a => (a.categoria && a.categoria.nomeCategoria) === filtroAtivo);

  if (filtradas.length === 0) {
    lista.innerHTML = '';
    vazio.style.display = 'flex';
    return;
  }

  vazio.style.display = 'none';
  lista.innerHTML = filtradas
    .slice()
    .sort((a, b) => new Date(b.dataAvaliacao) - new Date(a.dataAvaliacao))
    .map(renderizarCardSugestao)
    .join('');
}

function renderizarCardSugestao(a) {
  const nomeUsuario = (a.usuario && a.usuario.nome) || 'Usuário';
  const iniciais = obterIniciais(nomeUsuario);
  const nota = Number(a.nota) || 0;
  const estrelasHtml = Array.from({ length: 5 }, (_, i) =>
    `<i class="fas fa-star${i < nota ? '' : ' vazia'}"></i>`).join('');
  const categoriaNome = (a.categoria && a.categoria.nomeCategoria) || 'Geral';
  const dataFormatada = formatarData(a.dataAvaliacao);

  const statusChave = typeof chaveStatus === 'function' ? chaveStatus(a.status) : 'pendente';
  const statusLabel = typeof rotuloStatus === 'function' ? rotuloStatus(a.status) : (a.status || '');

  return `
    <div class="sugestao-card" id="card-${a.idAvaliacao}">
      <div class="sug-topo">
        <div class="sug-usuario">
          <div class="sug-avatar">${escapeHtml(iniciais)}</div>
          <div class="sug-user-info">
            <span class="sug-nome">${escapeHtml(nomeUsuario)}</span>
            <span class="sug-data">${dataFormatada}</span>
          </div>
        </div>
        <span class="sug-categoria">${escapeHtml(categoriaNome)}</span>
      </div>

      <div class="sug-estrelas">${estrelasHtml}</div>

      <p class="sug-texto">${escapeHtml(a.comentario || '')}</p>

      <div class="sug-rodape">
        <span class="sug-status sug-status-${statusChave}">${escapeHtml(statusLabel)}</span>
      </div>
    </div>
  `;
}

function formatarData(iso) {
  if (!iso) return '';
  const data = new Date(iso);
  if (isNaN(data.getTime())) return '';
  return data.toLocaleDateString('pt-BR');
}

function obterIniciais(nome) {
  const p = nome.split(' ');
  let ini = p[0].charAt(0).toUpperCase();
  if (p.length > 1) ini += p[p.length - 1].charAt(0).toUpperCase();
  return ini;
}


// ── FILTRAR SUGESTÕES ─────────────────────────────────────────────────
function filtrar(botao, categoria) {
  document.querySelectorAll('.filtro').forEach(b => b.classList.remove('ativo'));
  botao.classList.add('ativo');
  filtroAtivo = categoria;
  renderizarSugestoes();
}


// ── ABAS DE NAVEGAÇÃO ─────────────────────────────────────────────────
function trocarAba(botao, id) {
  document.querySelectorAll('.aba').forEach(b => b.classList.remove('ativa'));
  botao.classList.add('ativa');

  document.querySelectorAll('.aba-corpo').forEach(c => c.classList.add('oculto'));
  const alvo = document.getElementById('aba-' + id);
  if (alvo) {
    alvo.classList.remove('oculto');
    alvo.style.opacity = '0';
    requestAnimationFrame(() => {
      alvo.style.transition = 'opacity 0.25s ease';
      alvo.style.opacity = '1';
    });
  }
}


// ── SALVAR LOCAL (favoritos reais via API) ─────────────────────────────
async function salvarLocal() {
  if (!est) return;

  const usuarioId = Number(localStorage.getItem('idUsuario'));
  if (!Number.isFinite(usuarioId) || usuarioId <= 0) {
    window.location.href = 'login.html';
    return;
  }

  const btn = document.getElementById('btnSalvar');
  const icone = document.getElementById('iconeSalvar');
  const novoEstado = !salvo;

  try {
    if (novoEstado) {
      const resposta = await fetch(`${API_BASE}/locais-salvos`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usuarioId, estabelecimentoId: est.id }),
      });
      if (!resposta.ok) throw new Error('Erro ao salvar favorito.');
    } else {
      const resposta = await fetch(`${API_BASE}/locais-salvos/${usuarioId}/${est.id}`, {
        method: 'DELETE',
      });
      if (!resposta.ok) throw new Error('Erro ao remover favorito.');
    }

    salvo = novoEstado;
    btn.classList.toggle('salvo', salvo);
    icone.className = salvo ? 'fas fa-bookmark' : 'far fa-bookmark';
    mostrarToast(salvo ? 'Local salvo nos favoritos!' : 'Local removido dos favoritos');
  } catch (erro) {
    console.error('Erro ao alternar favorito:', erro);
    mostrarToast('Não foi possível atualizar os favoritos.', 'erro');
  }
}

async function verificarSeFavorito() {
  const usuarioId = Number(localStorage.getItem('idUsuario'));
  if (!Number.isFinite(usuarioId) || usuarioId <= 0 || !est) return;

  try {
    const resposta = await fetch(`${API_BASE}/locais-salvos/usuario/${usuarioId}`);
    if (!resposta.ok) return;
    const salvos = await resposta.json();
    const estaSalvo = Array.isArray(salvos) && salvos.some(s => Number(s.idEstabelecimento) === Number(est.id));

    if (estaSalvo) {
      salvo = true;
      document.getElementById('btnSalvar').classList.add('salvo');
      document.getElementById('iconeSalvar').className = 'fas fa-bookmark';
    }
  } catch (erro) {
    console.error('Erro ao verificar favorito:', erro);
  }
}


// ── IR PARA O MAPA ────────────────────────────────────────────────────
// Passa os dados reais para a tela de mapa existente via sessionStorage
function irParaMapa() {
  if (!est) return;

  const total = avaliacoes.length;
  const soma = avaliacoes.reduce((acc, a) => acc + (Number(a.nota) || 0), 0);
  const media = total > 0 ? (soma / total).toFixed(1) : '';

  sessionStorage.setItem('loc_id',         est.id);
  sessionStorage.setItem('loc_nome',       est.nome);
  sessionStorage.setItem('loc_endereco',   est.endereco);
  sessionStorage.setItem('loc_telefone',   est.telefone);
  sessionStorage.setItem('loc_horario',    est.horario);
  sessionStorage.setItem('loc_nota',       media);
  sessionStorage.setItem('loc_avaliacoes', String(total));
  sessionStorage.setItem('loc_logo',       est.logo);
  window.location.href = 'mapaCli.html';
}


// ── LIGAR ────────────────────────────────────────────────────────────
function ligarPara() {
  if (!est || !est.telefone) return;
  const numero = est.telefone.replace(/\D/g, '');
  window.location.href = `tel:${numero}`;
}


// ── NOVA SUGESTÃO ──────────────────────────────────────────────────────
// Leva para o mesmo fluxo de sugestão usado em InicioCli.html, em vez de
// um modal próprio duplicado.
function irParaSugestao() {
  if (!est) return;
  window.location.href = `./fazerSugestao.html?id=${est.id}&nome=${encodeURIComponent(est.nome)}`;
}


// ── TOAST ────────────────────────────────────────────────────────────
function mostrarToast(msg, tipo = 'sucesso') {
  const toast = document.getElementById('toast');
  const icone = document.getElementById('toastIcone');
  const msgEl = document.getElementById('toastMsg');

  msgEl.textContent = msg;
  icone.className   = tipo === 'erro' ? 'fas fa-exclamation-circle' : 'fas fa-check-circle';
  toast.classList.toggle('erro', tipo === 'erro');
  toast.classList.add('visivel');
  setTimeout(() => toast.classList.remove('visivel'), 3200);
}


// ── SAIR ─────────────────────────────────────────────────────────────
function confirmarSair() {
  localStorage.clear();
  sessionStorage.clear();
  window.location.href = 'login.html';
}
