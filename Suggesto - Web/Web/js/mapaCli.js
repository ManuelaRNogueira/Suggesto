const dadosEstab = {
  id:         sessionStorage.getItem('loc_id')         || '',
  nome:       sessionStorage.getItem('loc_nome')       || 'Estabelecimento',
  endereco:   sessionStorage.getItem('loc_endereco')   || '',
  telefone:   sessionStorage.getItem('loc_telefone')   || '',
  horario:    sessionStorage.getItem('loc_horario')    || '',
  nota:       sessionStorage.getItem('loc_nota')       || '',
  avaliacoes: sessionStorage.getItem('loc_avaliacoes') || '0',
  logo:       sessionStorage.getItem('loc_logo')       || '',
};

// Limpa sessionStorage logo após ler
['loc_id','loc_nome','loc_endereco','loc_telefone','loc_horario',
 'loc_nota','loc_avaliacoes','loc_logo']
  .forEach(k => sessionStorage.removeItem(k));

// URL do Google Maps para redirecionamento — usa o endereço real
const urlMaps = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(dadosEstab.endereco)}`;

// ── ESTADO ───────────────────────────────────────────────────────────
let localSalvo  = false;
let mapaLeaflet = null;


// ── INICIALIZA AO CARREGAR ───────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  preencherDados();
  verificarStatus();
  verificarSeFavorito();
  buscarCoordenadas(); // busca a localização real pelo endereço
});


// ── PREENCHER DADOS NA TELA ──────────────────────────────────────────
function preencherDados() {
  document.getElementById('nomeEstab').textContent      = dadosEstab.nome;
  document.getElementById('enderecoEstab').textContent  = dadosEstab.endereco || 'Endereço não informado';
  document.getElementById('horarioEstab').textContent   = dadosEstab.horario || 'Horário não informado';
  document.getElementById('telefoneEstab').textContent  = dadosEstab.telefone || 'Não informado';
  document.getElementById('notaEstab').textContent      = dadosEstab.nota || '—';
  document.getElementById('totalAvaliacoes').textContent = `(${dadosEstab.avaliacoes} avaliações)`;
  document.getElementById('modalSubtitulo').textContent = dadosEstab.nome;
  document.title = `${dadosEstab.nome} — Suggesto`;

  // Logo
  const logo = document.getElementById('logoEstab');
  if (dadosEstab.logo) {
    logo.src = dadosEstab.logo;
    logo.onerror = () => {
      logo.style.display = 'none';
      document.getElementById('logoPlaceholder').style.display = 'flex';
    };
  } else {
    logo.style.display = 'none';
    document.getElementById('logoPlaceholder').style.display = 'flex';
  }
}


// ── GEOCODING: ENDEREÇO → COORDENADAS REAIS (Nominatim) ──────────────
async function buscarCoordenadas() {
  mostrarCarregandoMapa();

  try {
    // Nominatim aceita endereço em texto e devolve lat/lng reais
    const url = `https://nominatim.openstreetmap.org/search?` +
      `q=${encodeURIComponent(dadosEstab.endereco)}` +
      `&format=json&limit=1&addressdetails=1`;

    const resposta = await fetch(url, {
      headers: {
        // Nominatim exige identificação do app no User-Agent
        'Accept-Language': 'pt-BR',
      }
    });

    const resultados = await resposta.json();

    if (resultados.length === 0) {
      // Endereço não encontrado — tenta só com cidade
      await buscarPorCidade();
      return;
    }

    const { lat, lon } = resultados[0];
    iniciarMapa(parseFloat(lat), parseFloat(lon));

  } catch (erro) {
    console.error('Erro ao buscar coordenadas:', erro);
    mostrarErrroMapa();
  }
}

// Fallback: busca só pelo nome do estabelecimento + cidade
async function buscarPorCidade() {
  try {
    const termoBusca = `${dadosEstab.nome}, Campinas, SP, Brasil`;
    const url = `https://nominatim.openstreetmap.org/search?` +
      `q=${encodeURIComponent(termoBusca)}` +
      `&format=json&limit=1`;

    const resposta  = await fetch(url);
    const resultados = await resposta.json();

    if (resultados.length > 0) {
      const { lat, lon } = resultados[0];
      iniciarMapa(parseFloat(lat), parseFloat(lon));
    } else {
      mostrarErrroMapa();
    }
  } catch {
    mostrarErrroMapa();
  }
}


// ── INICIAR MAPA COM AS COORDENADAS REAIS ────────────────────────────
function iniciarMapa(lat, lng) {
  // Remove o loader
  const loader = document.getElementById('mapaLoader');
  if (loader) loader.remove();

  const posicao = [lat, lng];

  // Cria o mapa Leaflet
  mapaLeaflet = L.map('mapa', {
    center: posicao,
    zoom: 16,
    zoomControl: false,
    scrollWheelZoom: false,
    doubleClickZoom: false,
    dragging: false,     // desativa arrastar — clique abre Google Maps
    touchZoom: false,
    keyboard: false,
    attributionControl: false,
  });

  // Tiles escuros do CartoDB (combina com o tema do projeto)
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    maxZoom: 19,
    subdomains: 'abcd',
  }).addTo(mapaLeaflet);

  // Pin SVG roxo personalizado
  const svgPin = `
    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="52" viewBox="0 0 40 52">
      <defs>
        <filter id="s" x="-30%" y="-20%" width="160%" height="160%">
          <feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="rgba(0,0,0,0.55)"/>
        </filter>
      </defs>
      <path d="M20 2C10.6 2 3 9.6 3 19c0 12 17 30 17 30s17-18 17-30C37 9.6 29.4 2 20 2z"
            fill="#7c3aed" filter="url(#s)"/>
      <circle cx="20" cy="19" r="9" fill="white"/>
      <circle cx="20" cy="19" r="5" fill="#7c3aed"/>
    </svg>`;

  const iconePin = L.divIcon({
    html: svgPin,
    className: '',
    iconSize:   [40, 52],
    iconAnchor: [20, 52],
    popupAnchor:[0, -54],
  });

  // Marker na posição real
  const marker = L.marker(posicao, { icon: iconePin }).addTo(mapaLeaflet);

  // Popup com nome e instrução
  marker.bindPopup(`
    <div style="
      font-family:'DM Sans',sans-serif;
      padding: 4px 2px;
    ">
      <strong style="font-size:13px;color:#f0f0f8;">${dadosEstab.nome}</strong><br>
      <span style="font-size:11px;color:#a78bfa;">
        Clique no mapa para abrir no Google Maps
      </span>
    </div>
  `, { className: 'popup-suggesto', closeButton: false });

  marker.openPopup();

  // Todo clique no mapa abre o Google Maps com o endereço real
  mapaLeaflet.on('click', abrirNoMaps);
  marker.on('click', abrirNoMaps);
}


// ── LOADER ENQUANTO BUSCA AS COORDENADAS ────────────────────────────
function mostrarCarregandoMapa() {
  const mapaEl = document.getElementById('mapa');
  const loader = document.createElement('div');
  loader.id = 'mapaLoader';
  loader.style.cssText = `
    position: absolute; inset: 0; z-index: 20;
    background: #0e0e16;
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    gap: 14px;
  `;
  loader.innerHTML = `
    <div style="
      width: 40px; height: 40px;
      border: 3px solid rgba(124,58,237,0.2);
      border-top-color: #7c3aed;
      border-radius: 50%;
      animation: girar 0.8s linear infinite;
    "></div>
    <p style="font-size:13px;color:rgba(240,240,248,0.5);font-family:'DM Sans',sans-serif;">
      Buscando localização...
    </p>
    <style>
      @keyframes girar { to { transform: rotate(360deg); } }
    </style>`;
  document.getElementById('mapaWrap').insertBefore(loader, mapaEl);
}

// ── ERRO AO BUSCAR COORDENADAS ───────────────────────────────────────
function mostrarErrroMapa() {
  const loader = document.getElementById('mapaLoader');
  if (loader) {
    loader.innerHTML = `
      <div style="font-size:32px;opacity:0.3;">📍</div>
      <p style="font-size:13px;color:rgba(240,240,248,0.4);text-align:center;padding:0 24px;font-family:'DM Sans',sans-serif;">
        Não foi possível encontrar o endereço no mapa.<br>
        <span style="color:#a78bfa;">Clique abaixo para ver no Google Maps.</span>
      </p>
      <button onclick="abrirNoMaps()" style="
        padding:10px 22px; border-radius:999px;
        background:#7c3aed; border:none; color:#fff;
        font-size:13px; font-weight:600; cursor:pointer;
        font-family:'DM Sans',sans-serif;
      ">
        Abrir no Google Maps
      </button>`;
  }
}


// ── ABRIR NO GOOGLE MAPS ─────────────────────────────────────────────
// Usa o endereço real — Maps faz o geocoding próprio dele
function abrirNoMaps() {
  window.open(urlMaps, '_blank', 'noopener,noreferrer');
}


// ── LIGAR ────────────────────────────────────────────────────────────
function ligarPara() {
  const numero = dadosEstab.telefone.replace(/\D/g, '');
  window.location.href = `tel:${numero}`;
}


// ── SALVAR LOCAL ─────────────────────────────────────────────────────
function salvarLocal() {
  localSalvo = !localSalvo;

  const btn   = document.getElementById('btnSalvar');
  const icone = document.getElementById('iconeSalvar');

  btn.classList.toggle('salvo', localSalvo);
  icone.className = localSalvo ? 'fas fa-bookmark' : 'far fa-bookmark';
  mostrarToast(localSalvo ? 'Local salvo nos favoritos!' : 'Local removido dos favoritos');

  // Persiste no localStorage
  const favoritos = JSON.parse(localStorage.getItem('sg_favoritos') || '[]');
  if (localSalvo) {
    if (!favoritos.includes(dadosEstab.nome)) favoritos.push(dadosEstab.nome);
  } else {
    const idx = favoritos.indexOf(dadosEstab.nome);
    if (idx > -1) favoritos.splice(idx, 1);
  }
  localStorage.setItem('sg_favoritos', JSON.stringify(favoritos));
}

function verificarSeFavorito() {
  const favoritos = JSON.parse(localStorage.getItem('sg_favoritos') || '[]');
  if (favoritos.includes(dadosEstab.nome)) {
    localSalvo = true;
    document.getElementById('btnSalvar').classList.add('salvo');
    document.getElementById('iconeSalvar').className = 'fas fa-bookmark';
  }
}


// ── VERIFICAR STATUS ABERTO/FECHADO ──────────────────────────────────
function verificarStatus() {
  const dot   = document.getElementById('statusDot');
  const texto = document.getElementById('statusTexto');
  const fecha = document.getElementById('statusFecha');

  const status = calcularStatusEstabelecimento(dadosEstab.horario);

  dot.className     = `status-dot ${status.aberto ? 'status-aberto' : 'status-fechado'}`;
  texto.textContent = status.label;
  texto.className   = `status-texto${status.aberto ? '' : ' fechado'}`;
  fecha.textContent = status.detalhe;
}


// ── MODAL SUGESTÃO ───────────────────────────────────────────────────
function abrirSugestao() {
  document.getElementById('modalSugestao').classList.add('aberto');
}

function fecharModal() {
  document.getElementById('modalSugestao').classList.remove('aberto');
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('modalSugestao').addEventListener('click', e => {
    if (e.target === document.getElementById('modalSugestao')) fecharModal();
  });
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') fecharModal();
});

function enviarSugestao() {
  const textarea = document.getElementById('textSugestao');
  if (!textarea.value.trim()) {
    textarea.style.borderColor = 'rgba(248,113,113,0.6)';
    setTimeout(() => textarea.style.borderColor = '', 1800);
    return;
  }
  fecharModal();
  textarea.value = '';
  mostrarToast('Sugestão enviada com sucesso!');
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