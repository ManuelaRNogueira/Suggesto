const API_BASE = "http://localhost:8080/api";
const PLACEHOLDER_ESTABELECIMENTO = "imagens/placeholder-local.png";
let locaisSalvosIds = new Set();

function obterIdUsuario() {
  const raw =
    localStorage.getItem("idUsuario") ?? sessionStorage.getItem("idUsuario");
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

function obterIdEstabelecimento(estab) {
  const candidatos = [
    estab?.idEstabelecimento,
    estab?.id_estabelecimento,
    estab?.id,
  ];

  for (const valor of candidatos) {
    const id = Number(valor);
    if (Number.isFinite(id) && id > 0) return id;
  }

  return null;
}

function urlFotoEstabelecimento(fotoPath) {
  const nome = fotoPath ? String(fotoPath).trim() : "";
  if (!nome) return PLACEHOLDER_ESTABELECIMENTO;
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `http://localhost:8080/uploads/${relativo}`;
}

function formatarMediaEstabelecimento(estab) {
  const candidatos = [
    estab?.mediaAvaliacoes,
    estab?.mediaAvaliacao,
    estab?.notaMedia,
    estab?.nota,
  ];

  for (const valor of candidatos) {
    const num = Number(valor);
    if (Number.isFinite(num) && num > 0) return num.toFixed(1);
  }

  return "N/A";
}

const SVG_SALVAR_OFF =
  '<svg class="salvar-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" /></svg>';
const SVG_SALVAR_ON =
  '<svg class="salvar-icon" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.8"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" /></svg>';

document.addEventListener("DOMContentLoaded", () => {
  carregarDadosUsuario();
  carregarEstabelecimentos();
});

function abrirSugestao() {
  window.location.href = "./fazerSugestao.html";
}

function irParaPaginaSugestao(nome, id) {
  if (!id) {
    console.error("Erro: ID do estabelecimento não encontrado.");
    return;
  }

  window.location.href = `./fazerSugestao.html?id=${id}&nome=${encodeURIComponent(nome)}`;
}

async function carregarIdsSalvos() {
  const idUsuario = localStorage.getItem("idUsuario");
  if (!idUsuario) return;

  try {
    const resposta = await fetch(
      `${API_BASE}/locais-salvos/usuario/${idUsuario}`,
    );
    if (!resposta.ok) return;

    const estabelecimentos = await resposta.json();
    locaisSalvosIds = new Set(
      estabelecimentos
        .map((estab) => obterIdEstabelecimento(estab))
        .filter((id) => id != null),
    );
  } catch (error) {
    console.error("Erro ao carregar favoritos:", error);
  }
}

async function carregarEstabelecimentos() {
  const grade = document.getElementById("locaisGrade");
  if (!grade) return;

  await carregarIdsSalvos();

  try {
    const resposta = await fetch(`${API_BASE}/estabelecimentos`);
    const estabelecimentos = await resposta.json();

    grade.innerHTML = "";

    estabelecimentos.forEach((estab) => {
      const card = document.createElement("div");
      card.className = "local-card";

      const categoriaCard = estab.categoria
        ? estab.categoria.toLowerCase()
        : "outros";
      card.dataset.categoria = categoriaCard;

      const nomeCerto = estab.nome || "Nome Indisponível";
      const idCerto = obterIdEstabelecimento(estab);
      const jaSalvo = idCerto ? locaisSalvosIds.has(idCerto) : false;
      const imagemURL = urlFotoEstabelecimento(estab.fotoPath);

      const imagemDiv = document.createElement("div");
      imagemDiv.className = "local-imagem";

      const imgFoto = document.createElement("img");
      imgFoto.className = "local-foto";
      imgFoto.alt = nomeCerto;
      imgFoto.src = imagemURL;
      imgFoto.onerror = function () {
        this.onerror = null;
        this.src = PLACEHOLDER_ESTABELECIMENTO;
      };
      imagemDiv.appendChild(imgFoto);

      imagemDiv.addEventListener("click", () => {
        window.location.href = "estabelecimentoCli.html";
      });

      const categoriaSpan = document.createElement("span");
      categoriaSpan.className = "local-categoria";
      categoriaSpan.textContent = estab.categoria || "Local";

      const btnFavorito = criarBotaoFavorito(idCerto, jaSalvo);

      imagemDiv.appendChild(categoriaSpan);
      imagemDiv.appendChild(btnFavorito);

      const infoDiv = document.createElement("div");
      infoDiv.className = "local-info";

      const topoDiv = document.createElement("div");
      topoDiv.className = "local-info-topo";

      const nomeContainer = document.createElement("div");

      const nomeEl = document.createElement("h3");
      nomeEl.className = "local-nome";
      nomeEl.textContent = nomeCerto;

      const enderecoEl = document.createElement("p");
      enderecoEl.className = "local-endereco";
      const enderecoCompleto = estab.rua
        ? `${estab.rua}, ${estab.numero}${estab.bairro ? ` - ${estab.bairro}` : ""} (${estab.cidade}/${estab.estado})`
        : "Endereço não informado";

      enderecoEl.innerHTML = `<i class="fas fa-map-marker-alt"></i> ${enderecoCompleto}`;

      nomeContainer.appendChild(nomeEl);
      nomeContainer.appendChild(enderecoEl);

      const notaDiv = document.createElement("div");
      notaDiv.className = "local-nota";
      notaDiv.innerHTML = `
                <i class="fas fa-star"></i>
                <span>${formatarMediaEstabelecimento(estab)}</span>
            `;

      topoDiv.appendChild(nomeContainer);
      topoDiv.appendChild(notaDiv);

      const rodapeDiv = document.createElement("div");
      rodapeDiv.className = "local-rodape";

      const tagSpan = document.createElement("span");
      tagSpan.className = "local-tag";
      tagSpan.textContent = `#${estab.categoria || "Sugestão"}`;

      const botao = document.createElement("button");
      botao.className = "local-btn-sugestao";
      botao.innerHTML = `<i class="fas fa-comment-alt"></i> Sugerir`;

      botao.addEventListener("click", () => {
        irParaPaginaSugestao(nomeCerto, idCerto);
      });

      rodapeDiv.appendChild(tagSpan);
      rodapeDiv.appendChild(botao);

      infoDiv.appendChild(topoDiv);
      infoDiv.appendChild(rodapeDiv);

      card.appendChild(imagemDiv);
      card.appendChild(infoDiv);

      grade.appendChild(card);
    });
  } catch (error) {
    console.error("Erro ao carregar estabelecimentos:", error);

    grade.innerHTML = `
            <p style="color: white; text-align: center; grid-column: 1/-1;">
                Não foi possível carregar os dados do servidor.
            </p>
        `;
  }
}

function criarBotaoFavorito(estabelecimentoId, salvo) {
  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = `local-favorito${salvo ? " salvo" : ""}`;
  btn.title = salvo ? "Remover dos salvos" : "Salvar local";
  btn.innerHTML = salvo ? SVG_SALVAR_ON : SVG_SALVAR_OFF;

  btn.addEventListener("click", (event) => {
    event.stopPropagation();
    toggleFavorito(estabelecimentoId, btn);
  });

  return btn;
}

function atualizarIconeFavorito(btn, salvo) {
  btn.classList.toggle("salvo", salvo);
  btn.innerHTML = salvo ? SVG_SALVAR_ON : SVG_SALVAR_OFF;
  btn.title = salvo ? "Remover dos salvos" : "Salvar local";
}

async function toggleFavorito(estabelecimentoId, btn) {
  const usuarioId = obterIdUsuario();

  if (!usuarioId) {
    window.location.href = "login.html";
    return;
  }

  const idEstab = Number(estabelecimentoId);
  if (!Number.isFinite(idEstab) || idEstab <= 0) {
    console.error("ID de estabelecimento inválido:", estabelecimentoId);
    return;
  }
  const salvo = btn.classList.contains("salvo");

  try {
    if (salvo) {
      const resposta = await fetch(
        `${API_BASE}/locais-salvos/${usuarioId}/${idEstab}`,
        { method: "DELETE" },
      );

      if (!resposta.ok) throw new Error("Erro ao remover favorito.");

      locaisSalvosIds.delete(idEstab);
      atualizarIconeFavorito(btn, false);
    } else {
      const resposta = await fetch(`${API_BASE}/locais-salvos`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          usuarioId: usuarioId,
          estabelecimentoId: idEstab,
        }),
      });

      if (!resposta.ok) throw new Error("Erro ao salvar favorito.");

      locaisSalvosIds.add(idEstab);
      atualizarIconeFavorito(btn, true);
    }
  } catch (error) {
    console.error("Erro ao alternar favorito:", error);
  }
}

function carregarDadosUsuario() {
  const nome = localStorage.getItem("nomeUsuario") || "Usuário";

  const elementoSaudacao = document.getElementById("saudacaoNome");
  const elementoSidebar = document.getElementById("sidebarNome");
  const elementoAvatar = document.getElementById("sidebarAvatar");

  if (elementoSaudacao)
    elementoSaudacao.innerText = `Olá, ${nome.split(" ")[0]} 👋`;

  if (elementoSidebar) elementoSidebar.innerText = nome;

  if (elementoAvatar)
    elementoAvatar.innerText = nome.substring(0, 2).toUpperCase();
}

function filtrarLocais() {
  const busca = document.getElementById("campoBusca").value.toLowerCase();
  const cards = document.querySelectorAll(".local-card");

  cards.forEach((card) => {
    const nomeElemento = card.querySelector(".local-nome");
    if (nomeElemento) {
      const nome = nomeElemento.textContent.toLowerCase();
      card.style.display = nome.includes(busca) ? "" : "none";
    }
  });
}

function filtrarCategoria(botao, categoria) {
  document
    .querySelectorAll(".filtro-chip")
    .forEach((b) => b.classList.remove("filtro-chip-ativo"));

  botao.classList.add("filtro-chip-ativo");

  const cards = document.querySelectorAll(".local-card");

  cards.forEach((card) => {
    card.style.display =
      categoria === "todos" || card.dataset.categoria === categoria
        ? ""
        : "none";
  });
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
