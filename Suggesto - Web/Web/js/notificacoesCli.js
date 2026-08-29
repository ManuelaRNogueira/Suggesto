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

function normalizarTexto(valor) {
  return (valor || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .trim();
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
        <span class="notif-card-titulo">${estab.nome}</span>
        <span class="notif-card-sub">${estab.categoria || ""} · Novo em ${cidade}</span>
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
        <span class="notif-card-titulo">${rec.nome}</span>
        <span class="notif-card-sub">${nomeEstab} · ${rec.custoPontos} pontos</span>
      </div>
      <span class="notif-card-tempo">${tempoRelativo(rec.dataCadastro)}</span>
    `;
    lista.appendChild(card);
  });

  return true;
}

function renderizarRespostas(avaliacoes) {
  const lista = document.getElementById("listaRespostas");
  const vazio = document.getElementById("vazioRespostas");
  lista.innerHTML = "";

  const respondidas = avaliacoes
    .filter((av) => av.resposta && av.resposta.trim())
    .sort((a, b) => new Date(b.dataResposta || 0) - new Date(a.dataResposta || 0));

  if (respondidas.length === 0) {
    vazio.style.display = "block";
    return false;
  }
  vazio.style.display = "none";

  respondidas.forEach((av) => {
    const nomeEstab = av.estabelecimento ? av.estabelecimento.nome : "Estabelecimento";
    const card = document.createElement("div");
    card.className = "notif-card";
    card.onclick = () => (window.location.href = "sugestoesCli.html");
    card.innerHTML = `
      <div class="notif-card-icone"><i class="fas fa-reply"></i></div>
      <div class="notif-card-corpo">
        <span class="notif-card-titulo">${nomeEstab} respondeu sua sugestão</span>
        <span class="notif-card-texto">${av.resposta}</span>
      </div>
      <span class="notif-card-tempo">${tempoRelativo(av.dataResposta)}</span>
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
