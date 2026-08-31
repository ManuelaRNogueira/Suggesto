const dadosEstab = {
  id:         sessionStorage.getItem('loc_id')         || '',
  nome:       sessionStorage.getItem('loc_nome')       || 'Estabelecimento',
  endereco:   sessionStorage.getItem('loc_endereco')   || '',
  telefone:   sessionStorage.getItem('loc_telefone')   || '',
  horario:    sessionStorage.getItem('loc_horario')    || '',
  nota:       sessionStorage.getItem('loc_nota')       || '',
  avaliacoes: sessionStorage.getItem('loc_avaliacoes') || '0',
  logo:       sessionStorage.getItem('loc_logo')       || '',
  rua:        sessionStorage.getItem('loc_rua')        || '',
  numero:     sessionStorage.getItem('loc_numero')     || '',
  cidade:     sessionStorage.getItem('loc_cidade')     || '',
  estado:     sessionStorage.getItem('loc_estado')     || '',
  lat:        lerCoordenadaSessao('loc_lat', -90, 90),
  lng:        lerCoordenadaSessao('loc_lng', -180, 180),
};

function lerCoordenadaSessao(chave, minimo, maximo) {
  const valor = sessionStorage.getItem(chave);
  if (valor == null || !valor.trim()) return null;
  const numero = Number(valor);
  return Number.isFinite(numero) && numero >= minimo && numero <= maximo ? numero : null;
}

// ── ESTADO ───────────────────────────────────────────────────────────
let localSalvo  = false;
let mapaLeaflet = null;
let coordenadasMapa = null;


// ── INICIALIZA AO CARREGAR ───────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  carregarDadosUsuario();
  preencherDados();
  verificarStatus();
  verificarSeFavorito();

  if (dadosEstab.lat !== null && dadosEstab.lng !== null) {
    iniciarMapa(dadosEstab.lat, dadosEstab.lng);
  } else {
    buscarCoordenadas();
  }
});


// ── SIDEBAR: NOME/AVATAR DO USUÁRIO ──────────────────────────────────
function carregarDadosUsuario() {
  const nome = localStorage.getItem('nomeUsuario') || 'Usuário';
  const idUsuario = localStorage.getItem('idUsuario');
  const elementoNome = document.getElementById('sidebarNome');
  const elementoAvatar = document.getElementById('sidebarAvatar');
  if (elementoNome) elementoNome.textContent = nome;
  if (elementoAvatar) elementoAvatar.textContent = nome.substring(0, 2).toUpperCase();

  // Busca a foto de perfil de verdade — só troca as iniciais se existir.
  if (idUsuario) {
    fetch(`${window.API_BASE}/usuarios/${idUsuario}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((usuario) => {
        const urlFoto = resolverUrlFotoUsuario(usuario?.fotoUrl);
        if (urlFoto && elementoAvatar) {
          elementoAvatar.innerHTML = `<img src="${urlFoto}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;display:block;">`;
          elementoAvatar.style.background = "transparent";
          elementoAvatar.style.boxShadow = "none";
          elementoAvatar.style.border = "none";
        }
      })
      .catch(() => {});
  }
}

// Mesma lógica usada pra foto de estabelecimento, sem placeholder — avatar
// sem foto mostra iniciais, não uma imagem substituta.
function resolverUrlFotoUsuario(fotoUrl) {
  const nome = fotoUrl ? String(fotoUrl).trim() : "";
  if (!nome) return "";
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${window.API_BASE.replace("/api", "")}/uploads/${relativo}`;
}

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
  const placeholder = document.getElementById('logoPlaceholder');
  if (dadosEstab.logo) {
    logo.src = dadosEstab.logo;
    logo.style.display = '';
    placeholder.style.display = 'none';
    logo.onerror = () => {
      logo.style.display = 'none';
      placeholder.style.display = 'flex';
    };
  } else {
    logo.style.display = 'none';
    placeholder.style.display = 'flex';
  }
}


// ── GEOCODING: ENDEREÇO → COORDENADAS REAIS (Nominatim) ──────────────
async function buscarCoordenadas() {
  mostrarCarregandoMapa();

  const consulta = montarConsultaGeocodificacao(true);
  if (!consulta) {
    mostrarErroMapa('Este estabelecimento ainda não possui endereço cadastrado.');
    return;
  }

  try {
    // Nominatim aceita endereço em texto e devolve lat/lng reais
    const url = `https://nominatim.openstreetmap.org/search?` +
      `q=${encodeURIComponent(consulta)}` +
      `&format=jsonv2&limit=1&addressdetails=1&countrycodes=br`;

    const resposta = await fetch(url, {
      headers: {
        'Accept-Language': 'pt-BR',
      }
    });

    if (!resposta.ok) {
      throw new Error(`Geocodificação indisponível (${resposta.status}).`);
    }

    const resultados = await resposta.json();

    if (resultados.length === 0) {
      // Alguns números ainda não constam no mapa; tenta localizar a rua.
      await buscarSemNumero();
      return;
    }

    const { lat, lon } = resultados[0];
    iniciarMapa(parseFloat(lat), parseFloat(lon));

  } catch (erro) {
    console.error('Erro ao buscar coordenadas:', erro);
    mostrarErroMapa();
  }
}

function normalizarTextoGeocodificacao(texto) {
  return String(texto || '')
    .replace(/['’`´]/g, ' ')
    .replace(/[,–—-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function montarConsultaGeocodificacao(incluirNumero) {
  if (dadosEstab.rua && dadosEstab.cidade) {
    return [
      normalizarTextoGeocodificacao(dadosEstab.rua),
      incluirNumero ? normalizarTextoGeocodificacao(dadosEstab.numero) : '',
      normalizarTextoGeocodificacao(dadosEstab.cidade),
      normalizarTextoGeocodificacao(dadosEstab.estado),
      'Brasil',
    ].filter(Boolean).join(', ');
  }

  if (!incluirNumero) {
    const partes = dadosEstab.endereco.split(',').map(parte => parte.trim()).filter(Boolean);
    if (partes.length >= 3) {
      return [partes[0], partes[1], partes[partes.length - 1], 'Brasil']
        .map(normalizarTextoGeocodificacao)
        .filter(Boolean)
        .join(', ');
    }
  }

  return normalizarTextoGeocodificacao(dadosEstab.endereco);
}

// O serviço de mapas gratuito só aceita perguntas num ritmo devagar,
// então esperamos um pouquinho mais de 1 segundo antes de tentar de novo
// com um endereço mais simples — como esperar sua vez numa fila de
// atendimento grátis.
async function buscarSemNumero() {
  try {
    await new Promise(resolve => setTimeout(resolve, 1100));
    const termoBusca = montarConsultaGeocodificacao(false);
    const url = `https://nominatim.openstreetmap.org/search?` +
      `q=${encodeURIComponent(termoBusca)}` +
      `&format=jsonv2&limit=1&countrycodes=br`;

    const resposta  = await fetch(url);
    if (!resposta.ok) throw new Error(`Geocodificação indisponível (${resposta.status}).`);
    const resultados = await resposta.json();

    if (resultados.length > 0) {
      const { lat, lon } = resultados[0];
      iniciarMapa(parseFloat(lat), parseFloat(lon));
    } else {
      mostrarErroMapa();
    }
  } catch {
    mostrarErroMapa();
  }
}


// ── INICIAR MAPA COM AS COORDENADAS REAIS ────────────────────────────
function iniciarMapa(lat, lng) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    mostrarErroMapa('O endereço retornou coordenadas inválidas.');
    return;
  }

  if (typeof L === 'undefined') {
    mostrarErroMapa('Não foi possível carregar o componente do mapa.');
    return;
  }

  // Remove o loader
  const loader = document.getElementById('mapaLoader');
  if (loader) loader.remove();

  const posicao = [lat, lng];
  coordenadasMapa = { lat, lng };

  // Cria o mapa Leaflet
  mapaLeaflet = L.map('mapa', {
    center: posicao,
    zoom: 16,
    zoomControl: false,
    scrollWheelZoom: true,
    doubleClickZoom: true,
    dragging: true,
    touchZoom: true,
    keyboard: true,
    attributionControl: true,
  });

  // Tiles padrão do OpenStreetMap — gratuito, sem chave de API (o CartoDB
  // passou a exigir chave até pro tile "dark_all" que usávamos antes). O
  // visual escuro agora vem de um filtro CSS em cima do tile (ver
  // ".leaflet-tile-pane" em css/mapaCli.css), sem depender de nenhum serviço
  // pago pra isso.
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap',
  }).addTo(mapaLeaflet);
  L.control.zoom({ position: 'bottomleft' }).addTo(mapaLeaflet);

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

  const popup = document.createElement('div');
  popup.className = 'popup-suggesto-conteudo';
  const nomePopup = document.createElement('strong');
  nomePopup.textContent = dadosEstab.nome;
  const enderecoPopup = document.createElement('span');
  enderecoPopup.textContent = dadosEstab.endereco;
  popup.append(nomePopup, enderecoPopup);

  marker.bindPopup(popup, { className: 'popup-suggesto', closeButton: false });

  marker.openPopup();
  setTimeout(() => mapaLeaflet?.invalidateSize(), 0);
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
function mostrarErroMapa(mensagem = 'Não foi possível encontrar o endereço no mapa.') {
  const loader = document.getElementById('mapaLoader');
  if (loader) {
    loader.innerHTML = `
      <div style="font-size:32px;opacity:0.3;">📍</div>
      <p style="font-size:13px;color:rgba(240,240,248,0.4);text-align:center;padding:0 24px;font-family:'DM Sans',sans-serif;">
        ${mensagem}<br>
        <span style="color:#a78bfa;">Você ainda pode abrir a rota externamente.</span>
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
  const consulta = coordenadasMapa
    ? `${coordenadasMapa.lat},${coordenadasMapa.lng}`
    : dadosEstab.endereco;
  const urlMaps = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(consulta)}`;
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

// ── MODAL SAIR ────────────────────────────────────────────────────────
function abrirModalSair() {
  document.getElementById('modalSair')?.classList.add('aberto');
}

function fecharModalSair() {
  document.getElementById('modalSair')?.classList.remove('aberto');
}

function confirmarSair() {
  localStorage.clear();
  window.location.href = 'login.html';
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
