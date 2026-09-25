const API_BASE = window.API_BASE;
const DIAS_NOVO = 30;

document.addEventListener("DOMContentLoaded", () => {
  carregarDadosUsuario();
  carregarNotificacoes();
});

function obterIdUsuario() {
  const raw =
    localStorage.getItem("idUsuario") ?? sessionStorage.getItem("idUsuario");
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

// Escapa texto vindo da API antes de jogar no HTML, igual ao admEscapar do
// painel admin (js/admApi.js) - impede XSS armazenado em nome, comentario e
// resposta que o usuario digita.
function escapeHtml(texto) {
  const div = document.createElement("div");
  div.textContent = texto ?? "";
  return div.innerHTML;
}

function diasDesde(dataIso) {
  if (!dataIso) return Infinity;
  const diffMs = Date.now() - new Date(dataIso).getTime();
  return diffMs / (1000 * 60 * 60 * 24);
}

function tempoRelativo(dataIso) {
  if (!dataIso) return "";
  const dias = Math.floor(diasDesde(dataIso));
  if (dias <= 0) return "Hoje";
  if (dias === 1) return "Há 1 dia";
  return `Há ${dias} dias`;
}

async function carregarNotificacoes() {
  const idUsuario = obterIdUsuario();
  if (!idUsuario) {
    window.location.href = "login.html";
    return;
  }

  try {
    const [usuario, estabelecimentos, recompensas, avaliacoes] = await Promise.all([
      fetch(`${API_BASE}/usuarios/${idUsuario}`).then((r) => (r.ok ? r.json() : null)),
      fetch(`${API_BASE}/estabelecimentos`).then((r) => (r.ok ? r.json() : [])),
      fetch(`${API_BASE}/recompensas`).then((r) => (r.ok ? r.json() : [])),
      fetch(`${API_BASE}/avaliacoes/usuario/${idUsuario}`).then((r) => (r.ok ? r.json() : [])),
    ]);

    const temNovidade = [
      renderizarEstabelecimentos(usuario, Array.isArray(estabelecimentos) ? estabelecimentos : []),
      renderizarRecompensas(Array.isArray(recompensas) ? recompensas : []),
      renderizarRespostas(Array.isArray(avaliacoes) ? avaliacoes : []),
    ].some(Boolean);

    document.getElementById("listaVaziaGeral").style.display = temNovidade ? "none" : "flex";
  } catch (erro) {
    console.error("Erro ao carregar notificações:", erro);
  }
}

function renderizarEstabelecimentos(usuario, estabelecimentos) {
  const lista = document.getElementById("listaEstabelecimentos");
  const aviso = document.getElementById("avisoSemCidade");
  const vazio = document.getElementById("vazioEstabelecimentos");
  const rotuloCidade = document.getElementById("notifCidadeTexto");

  const cidade = usuario?.cidade ? usuario.cidade.trim() : "";
  lista.innerHTML = "";

  if (!cidade) {
    aviso.style.display = "flex";
    vazio.style.display = "none";
    rotuloCidade.textContent = "";
    return false;
  }
  aviso.style.display = "none";
  rotuloCidade.textContent = `em ${cidade}`;

  const cidadeNormalizada = normalizarTexto(cidade);
  const novos = estabelecimentos
    .filter((estab) => normalizarTexto(estab.cidade) === cidadeNormalizada)
    .filter((estab) => diasDesde(estab.dataCadastro) <= DIAS_NOVO)
    .sort((a, b) => new Date(b.dataCadastro) - new Date(a.dataCadastro));

  if (novos.length === 0) {
    vazio.style.display = "block";
    return false;
  }
  vazio.style.display = "none";

  novos.forEach((estab) => {
    const id = estab.idEstabelecimento ?? estab.id_estabelecimento ?? estab.id;
    const card = document.createElement("div");
    card.className = "notif-card";
    card.onclick = () => (window.location.href = `estabelecimentoCli.html?id=${id}`);
    card.innerHTML = `
      <div class="notif-card-icone"><i class="fas fa-store"></i></div>
      <div class="notif-card-corpo">
        <span class="notif-card-titulo">${escapeHtml(estab.nome)}</span>
        <span class="notif-card-sub">${escapeHtml(estab.categoria || "")} · Novo em ${escapeHtml(cidade)}</span>
      </div>
      <span class="notif-card-tempo">${tempoRelativo(estab.dataCadastro)}</span>
    `;
    lista.appendChild(card);
  });

  return true;
}

function renderizarRecompensas(recompensas) {
  const lista = document.getElementById("listaRecompensas");
  const vazio = document.getElementById("vazioRecompensas");
  lista.innerHTML = "";

  const novas = recompensas
    .filter((rec) => diasDesde(rec.dataCadastro) <= DIAS_NOVO)
    .sort((a, b) => new Date(b.dataCadastro) - new Date(a.dataCadastro));

  if (novas.length === 0) {
    vazio.style.display = "block";
    return false;
  }
  vazio.style.display = "none";

  novas.forEach((rec) => {
    const nomeEstab = rec.estabelecimento ? rec.estabelecimento.nome : "Estabelecimento";
    const card = document.createElement("div");
    card.className = "notif-card";
    card.onclick = () => (window.location.href = "lojapontosCli.html");
    card.innerHTML = `
      <div class="notif-card-icone"><i class="fas fa-gift"></i></div>
      <div class="notif-card-corpo">
        <span class="notif-card-titulo">${escapeHtml(rec.nome)}</span>
        <span class="notif-card-sub">${escapeHtml(nomeEstab)} · ${rec.custoPontos} pontos</span>
      </div>
      <span class="notif-card-tempo">${tempoRelativo(rec.dataCadastro)}</span>
    `;
    lista.appendChild(card);
  });

  return true;
}

// Novidades das sugestões do cliente: resposta escrita e decisão (aceita ou
// recusada, com o motivo), a mais recente primeiro.
function renderizarRespostas(avaliacoes) {
  const lista = document.getElementById("listaRespostas");
  const vazio = document.getElementById("vazioRespostas");
  lista.innerHTML = "";

  const eventos = [];
  avaliacoes.forEach((av) => {
    const nomeEstab = escapeHtml(av.estabelecimento ? av.estabelecimento.nome : "Estabelecimento");
    if (av.resposta && av.resposta.trim()) {
      eventos.push({ data: av.dataResposta, icone: "fa-reply",
        titulo: `${nomeEstab} respondeu sua sugestão`, texto: escapeHtml(av.resposta) });
    }
    const chave = chaveStatus(av.status);
    if (chave === "aceita" && av.dataDecisao) {
      eventos.push({ data: av.dataDecisao, icone: "fa-circle-check",
        titulo: `${nomeEstab} aceitou sua sugestão`, texto: `+500 pontos · ${escapeHtml(av.comentario)}` });
    } else if (chave === "recusada" && av.dataDecisao) {
      eventos.push({ data: av.dataDecisao, icone: "fa-circle-xmark",
        titulo: `${nomeEstab} recusou sua sugestão`, texto: `Motivo: ${escapeHtml(av.motivoRecusa || "não informado")}` });
    }
  });
  eventos.sort((a, b) => new Date(b.data || 0) - new Date(a.data || 0));

  if (eventos.length === 0) {
    vazio.style.display = "block";
    return false;
  }
  vazio.style.display = "none";

  eventos.forEach((ev) => {
    const card = document.createElement("div");
    card.className = "notif-card";
    card.onclick = () => (window.location.href = "sugestoesCli.html");
    card.innerHTML = `
      <div class="notif-card-icone"><i class="fas ${ev.icone}"></i></div>
      <div class="notif-card-corpo">
        <span class="notif-card-titulo">${ev.titulo}</span>
        <span class="notif-card-texto">${ev.texto}</span>
      </div>
      <span class="notif-card-tempo">${tempoRelativo(ev.data)}</span>
    `;
    lista.appendChild(card);
  });

  return true;
}

function carregarDadosUsuario() {
  const nome = localStorage.getItem("nomeUsuario") || "Usuário";
  const idUsuario = obterIdUsuario();

  const elementoSidebar = document.getElementById("sidebarNome");
  const elementoAvatar = document.getElementById("sidebarAvatar");

  if (elementoSidebar) elementoSidebar.innerText = nome;
  if (elementoAvatar) elementoAvatar.innerText = nome.substring(0, 2).toUpperCase();

  if (idUsuario) {
    fetch(`${API_BASE}/usuarios/${idUsuario}`)
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

function resolverUrlFotoUsuario(fotoUrl) {
  const nome = fotoUrl ? String(fotoUrl).trim() : "";
  if (!nome) return "";
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${API_BASE.replace("/api", "")}/uploads/${relativo}`;
}

function abrirModalSair() {
  const modal = document.getElementById("modalSair");
  if (modal) modal.classList.add("aberto");
}

function fecharModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove("aberto");
}

function confirmarSair() {
  localStorage.clear();
  window.location.href = "login.html";
}
