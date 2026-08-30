const API_BASE = window.API_BASE;
let locaisSalvosIds = new Set();

// Opções passadas pra criarCardEstabelecimento (ver js/localCard.js) em
// todo card desta página: favorito de verdade (consulta/alterna
// locaisSalvosIds), diferente de Locais Salvos onde tudo já está salvo.
const opcoesCardCliente = {
  verificarSalvo: (id) => (id ? locaisSalvosIds.has(id) : false),
  aoClicarFavorito: toggleFavorito,
  aoClicarSugerir: (id, nome) => irParaPaginaSugestao(nome, id),
};

function obterIdUsuario() {
  const raw =
    localStorage.getItem("idUsuario") ?? sessionStorage.getItem("idUsuario");
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

document.addEventListener("DOMContentLoaded", () => {
  carregarDadosUsuario();
  iniciarSecoesDeLocais();
  gerarChipsCategoria("filtrosRapidos", "filtro-chip");
});

// Painel de categorias começa fechado (ver .filtros-rapidos em
// inicioCli.css) — só aparece quando a pessoa clica em "Filtrar".
function abrirFiltro() {
  const painel = document.getElementById("filtrosRapidos");
  const botao = document.querySelector(".locais-filtro");
  if (!painel) return;
  const aberto = painel.classList.toggle("aberto");
  botao?.classList.toggle("ativo", aberto);
}

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

// ── Home: "Perto de você" (raio real) + "Descubra Novos Locais" ───────────
// Um estabelecimento nunca aparece nas duas seções. Fluxo: carrega a lista
// completa uma vez → mostra "Descubra Novos Locais" com tudo (não trava a
// página esperando a permissão de localização) → pede a localização →
// quando ela resolver (com ou sem sucesso), classifica por distância (ou
// cai no fallback por cidade se a localização não estiver disponível) e
// re-renderiza as duas seções sem duplicidade.

let estabelecimentosCache = [];
let idsPertoDeVoce = new Set();

async function iniciarSecoesDeLocais() {
  const grade = document.getElementById("locaisGrade");
  if (!grade) return;

  await carregarIdsSalvos();

  try {
    const resposta = await fetch(`${API_BASE}/estabelecimentos`);
    estabelecimentosCache = await resposta.json();
  } catch (error) {
    console.error("Erro ao carregar estabelecimentos:", error);
    grade.innerHTML = `
            <p style="color: white; text-align: center; grid-column: 1/-1;">
                Não foi possível carregar os dados do servidor.
            </p>
        `;
    return;
  }

  renderizarDescubraNovosLocais();
  carregarPertoDeVoce();
}

function renderizarDescubraNovosLocais() {
  const grade = document.getElementById("locaisGrade");
  if (!grade) return;

  grade.innerHTML = "";
  estabelecimentosCache
    .filter((estab) => !idsPertoDeVoce.has(obterIdEstabelecimento(estab)))
    .forEach((estab) => grade.appendChild(criarCardEstabelecimento(estab, opcoesCardCliente)));
}

async function carregarPertoDeVoce() {
  const secao = document.getElementById("recomendadosSecao");
  const grade = document.getElementById("recomendadosGrade");
  const vazio = document.getElementById("recomendadosVazio");
  const rotuloCidade = document.getElementById("recomendadosCidade");
  if (!secao || !grade) return;

  // Estado de carregamento discreto — evita mostrar uma classificação errada
  // enquanto a localização ainda não chegou.
  secao.style.display = "";
  if (vazio) vazio.classList.remove("visivel");
  grade.innerHTML = `<p style="color: var(--cor-texto-fraco, #a0a0b8); grid-column: 1/-1; font-size: 13px;">Buscando locais perto de você…</p>`;

  const localizacao = await obterLocalizacaoUsuario();

  let proximos;
  if (localizacao) {
    if (rotuloCidade) rotuloCidade.textContent = "";
    proximos = estabelecimentosCache
      .map((estab) => {
        if (typeof estab.lat !== "number" || typeof estab.lng !== "number") return null;
        const distancia = calcularDistanciaKm(localizacao.lat, localizacao.lng, estab.lat, estab.lng);
        return distancia <= RAIO_PERTO_KM ? { estab, distancia } : null;
      })
      .filter(Boolean)
      .sort((a, b) => a.distancia - b.distancia);
  } else {
    // Sem permissão/indisponível/timeout — mantém o comportamento anterior
    // (recomendação pela cidade cadastrada no perfil) como fallback.
    proximos = await buscarRecomendadosPorCidade(rotuloCidade);
  }

  idsPertoDeVoce = new Set(proximos.map((p) => obterIdEstabelecimento(p.estab)));

  grade.innerHTML = "";

  if (proximos.length === 0) {
    if (vazio) {
      vazio.querySelector("p").textContent = localizacao
        ? `Nenhum estabelecimento a menos de ${RAIO_PERTO_KM} km de você`
        : "Permita o acesso à localização ou preencha seu endereço no perfil para recomendarmos os melhores locais perto de você";
      vazio.classList.add("visivel");
    }
  } else {
    if (vazio) vazio.classList.remove("visivel");
    proximos
      .slice(0, 6)
      .forEach(({ estab, distancia }) =>
        grade.appendChild(
          criarCardEstabelecimento(estab, {
            ...opcoesCardCliente,
            ...(distancia != null ? { distanciaKm: distancia } : {}),
          }),
        ),
      );
  }

  // Agora que sabemos quem ficou em "Perto de você", tira essas mesmas
  // pessoas de "Descubra Novos Locais".
  renderizarDescubraNovosLocais();
}

// Fallback quando não há localização real: mesma lógica de sempre (cidade do
// perfil), só reformatada pro mesmo formato { estab, distancia } do cálculo
// por coordenadas — aqui distancia fica null porque não é uma medida real.
async function buscarRecomendadosPorCidade(rotuloCidade) {
  const idUsuario = obterIdUsuario();
  if (!idUsuario) return [];

  try {
    const resposta = await fetch(
      `${API_BASE}/estabelecimentos/recomendados?idUsuario=${idUsuario}`,
    );
    if (!resposta.ok) return [];

    const dados = await resposta.json();
    const estabelecimentos = Array.isArray(dados.estabelecimentos) ? dados.estabelecimentos : [];
    if (rotuloCidade) rotuloCidade.textContent = dados.cidade || "";
    return estabelecimentos.map((estab) => ({ estab, distancia: null }));
  } catch (error) {
    console.error("Erro ao carregar recomendados por cidade:", error);
    return [];
  }
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
  const idUsuario = obterIdUsuario();

  const elementoSaudacao = document.getElementById("saudacaoNome");
  const elementoSidebar = document.getElementById("sidebarNome");
  const elementoAvatar = document.getElementById("sidebarAvatar");

  if (elementoSaudacao)
    elementoSaudacao.innerText = `Olá, ${nome.split(" ")[0]}`;

  if (elementoSidebar) elementoSidebar.innerText = nome;

  if (elementoAvatar)
    elementoAvatar.innerText = nome.substring(0, 2).toUpperCase();

  // Busca a foto de perfil de verdade — só troca as iniciais se existir.
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

// Mesma lógica usada pra foto de estabelecimento (ver js/localCard.js), sem
// placeholder — avatar sem foto mostra iniciais, não uma imagem substituta.
function resolverUrlFotoUsuario(fotoUrl) {
  const nome = fotoUrl ? String(fotoUrl).trim() : "";
  if (!nome) return "";
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${API_BASE.replace("/api", "")}/uploads/${relativo}`;
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
