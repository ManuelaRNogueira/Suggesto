// Sugestões do painel admin — versão web da tela equivalente do desktop
// (Suggesto_DesktopReact/renderer/src/pages/admin/Sugestoes.jsx). Usa os
// mesmos endpoints (ver js/admApi.js): GET /admin/sugestoes,
// PATCH /avaliacoes/{id}/status, PATCH /avaliacoes/{id}/resposta,
// GET /planos/meu (pra saber se o plano permite exportar CSV).

const POR_PAGINA = 12;

// Transições oferecidas em cada estado. Estado final não oferece ação.
const ACOES = {
  pendente: ["implementado", "recusado"],
  implementado: [],
  recusado: ["pendente"],
};

const STATUS_LIST = [
  { id: "pendente", label: "Pendente" },
  { id: "implementado", label: "Implementado" },
  { id: "recusado", label: "Recusado" },
];

let sugestoes = [];
let podeExportar = true;

let busca = "";
let statusAtivo = "todos";
let categoriaAtiva = "todas";
let ordem = "recente";
let pagina = 1;

let respondendoId = null;
let textoResposta = "";
let salvandoId = null;
let enviandoRespostaId = null;

document.addEventListener("DOMContentLoaded", () => {
  if (!admVerificarSessao()) return;
  montarConta();
  carregar();

  document.getElementById("btnSair").addEventListener("click", () => {
    if (!confirm("Encerrar sessão?")) return;
    localStorage.clear();
    window.location.href = "login.html";
  });

  document.getElementById("campoBusca").addEventListener("input", (e) => {
    busca = e.target.value;
    pagina = 1;
    renderizar();
  });

  document.getElementById("selectOrdem").addEventListener("change", (e) => {
    ordem = e.target.value;
    renderizar();
  });

  document.getElementById("btnExportarCsv").addEventListener("click", exportarCsv);

  document.getElementById("btnPaginaAnterior").addEventListener("click", () => {
    pagina -= 1;
    renderizar();
  });
  document.getElementById("btnPaginaProxima").addEventListener("click", () => {
    pagina += 1;
    renderizar();
  });

  document.getElementById("chipsStatus").addEventListener("click", (e) => {
    const chip = e.target.closest("[data-status]");
    if (!chip) return;
    statusAtivo = chip.dataset.status;
    pagina = 1;
    renderizar();
  });

  document.getElementById("listaCategorias").addEventListener("click", (e) => {
    const item = e.target.closest("[data-categoria]");
    if (!item) return;
    categoriaAtiva = item.dataset.categoria;
    pagina = 1;
    renderizar();
  });
});

function montarConta() {
  const nome = localStorage.getItem("nomeUsuario") || "Administrador";
  const email = localStorage.getItem("emailUsuario") || "";
  document.getElementById("contaNome").textContent = nome;
  document.getElementById("contaAvatar").textContent = admIniciais(nome);
  if (email) document.getElementById("contaEmail").textContent = email;
}

async function carregar() {
  try {
    sugestoes = (await admBuscarSugestoes()) || [];
  } catch (e) {
    const alvo = document.getElementById("erro");
    alvo.textContent = `Não foi possível carregar as sugestões (${e.message}).`;
    alvo.hidden = false;
    document.getElementById("estadoCarregando").hidden = true;
    document.getElementById("resumoSub").textContent = "Sem conexão com a API";
    return;
  }

  // Exportação de dados é um recurso de plano — se der erro (ex: rota fora do
  // ar), assume liberado em vez de travar a página inteira por causa disso.
  try {
    const plano = await admBuscarMeuPlano();
    podeExportar = plano?.permiteExportacao !== false;
  } catch (e) {
    podeExportar = true;
  }

  document.getElementById("estadoCarregando").hidden = true;
  document.getElementById("conteudoSugestoes").hidden = false;
  renderizar();
}

function contagensStatus() {
  const base = { todos: sugestoes.length };
  STATUS_LIST.forEach((s) => {
    base[s.id] = sugestoes.filter((x) => x.statusUi === s.id).length;
  });
  return base;
}

function categoriasComContagem() {
  const mapa = new Map();
  sugestoes.forEach((s) => {
    const nome = s.categoria || "Sem categoria";
    mapa.set(nome, (mapa.get(nome) || 0) + 1);
  });
  return [...mapa.entries()].sort((a, b) => b[1] - a[1]);
}

function sugestoesFiltradas() {
  const termo = busca.trim().toLowerCase();
  const lista = sugestoes.filter((s) => {
    if (statusAtivo !== "todos" && s.statusUi !== statusAtivo) return false;
    if (categoriaAtiva !== "todas" && (s.categoria || "Sem categoria") !== categoriaAtiva) return false;
    if (!termo) return true;
    return [s.comentario, s.autor, s.estabelecimento, s.categoria]
      .filter(Boolean)
      .some((campo) => campo.toLowerCase().includes(termo));
  });

  const data = (s) => new Date(s.dataAvaliacao || 0).getTime();
  return [...lista].sort((a, b) => {
    if (ordem === "antigo") return data(a) - data(b);
    if (ordem === "nota") return (b.nota || 0) - (a.nota || 0);
    if (ordem === "az")
      return admTituloSugestao(a.comentario).localeCompare(admTituloSugestao(b.comentario), "pt-BR");
    // Prioridade: clientes de nível mais alto sobem na fila; empate cai na data.
    if (ordem === "prioridade") return (b.prioridade || 1) - (a.prioridade || 1) || data(b) - data(a);
    return data(b) - data(a);
  });
}

function renderizar() {
  const filtradas = sugestoesFiltradas();
  const totalPaginas = Math.max(1, Math.ceil(filtradas.length / POR_PAGINA));
  if (pagina > totalPaginas) pagina = totalPaginas;
  if (pagina < 1) pagina = 1;
  const visiveis = filtradas.slice((pagina - 1) * POR_PAGINA, pagina * POR_PAGINA);

  document.getElementById("resumoSub").textContent =
    `${filtradas.length} de ${sugestoes.length} ${sugestoes.length === 1 ? "sugestão" : "sugestões"} em vista`;

  renderizarChipsStatus();
  renderizarCategorias();
  renderizarLista(visiveis);
  renderizarPaginacao(totalPaginas);
  atualizarBotaoExportar();
}

function renderizarChipsStatus() {
  const contagens = contagensStatus();
  const chips = [{ id: "todos", label: "Todas" }, ...STATUS_LIST];
  document.getElementById("chipsStatus").innerHTML = chips
    .map(
      (s) => `
    <button type="button" class="sug-chip${statusAtivo === s.id ? " ativo" : ""}${s.id !== "todos" ? ` st-${s.id}` : ""}" data-status="${s.id}">
      ${s.id !== "todos" ? '<span class="sug-chip-ponto"></span>' : ""}
      ${s.label}
      <span class="sug-chip-num">${contagens[s.id] ?? 0}</span>
    </button>`,
    )
    .join("");
}

function renderizarCategorias() {
  const categorias = categoriasComContagem();
  const itens = [
    `<li>
      <button type="button" class="sug-cat${categoriaAtiva === "todas" ? " ativo" : ""}" data-categoria="todas">
        Todas <span>${sugestoes.length}</span>
      </button>
    </li>`,
    ...categorias.map(
      ([nome, qtd]) => `
    <li>
      <button type="button" class="sug-cat${categoriaAtiva === nome ? " ativo" : ""}" data-categoria="${admEscapar(nome)}">
        ${admEscapar(nome)} <span>${qtd}</span>
      </button>
    </li>`,
    ),
  ];
  document.getElementById("listaCategorias").innerHTML = itens.join("");
}

function renderizarLista(visiveis) {
  const lista = document.getElementById("listaSugestoes");
  if (visiveis.length === 0) {
    lista.innerHTML = `<p class="estado-carregando">Nenhuma sugestão bate com esse filtro.</p>`;
    return;
  }
  lista.innerHTML = visiveis.map((s) => cartaoHtml(s)).join("");
}

function cartaoHtml(s) {
  const acoes = ACOES[s.statusUi] || [];
  const estaSalvando = salvandoId === s.id;
  const estaRespondendo = respondendoId === s.id;
  const estaEnviando = enviandoRespostaId === s.id;

  return `
    <li class="sug-card st-${s.statusUi}">
      <div class="sug-card-topo">
        <span class="pill ${s.statusUi}">${admLabelStatus(s.statusUi)}</span>
        <span class="sug-card-id">#${s.id}</span>
        ${s.nota != null ? `<span class="sug-card-nota">★ ${s.nota}</span>` : ""}
        <span class="sug-card-tempo">${admFormatarData(s.dataAvaliacao)}</span>
      </div>

      <p class="sug-card-txt">${admEscapar(admTituloSugestao(s.comentario))}</p>

      <div class="sug-card-meta">
        <span class="sug-card-autor">
          <span class="sug-card-avatar">${admIniciais(s.autor)}</span>
          ${admEscapar(s.autor || "Autor desconhecido")}
          ${s.nivelAutor && s.nivelAutor !== "bronze" ? `<span class="sug-nivel nivel-${s.nivelAutor}">${admEscapar(s.nivelAutorNome || "")}</span>` : ""}
        </span>
        <span class="sug-card-sep">·</span>
        <span>${admEscapar(s.categoria || "Sem categoria")}</span>
        ${s.estabelecimento ? `<span class="sug-card-sep">·</span><span>${admEscapar(s.estabelecimento)}</span>` : ""}
      </div>

      ${
        s.resposta && !estaRespondendo
          ? `<div class="sug-resposta">
        <div class="sug-resposta-topo">
          <span class="sug-resposta-rotulo">Sua resposta</span>
          <button type="button" class="sug-resposta-editar" onclick="sugAbrirResposta(${s.id})">Editar</button>
        </div>
        <p class="sug-resposta-texto">${admEscapar(s.resposta)}</p>
        ${s.respondidoPor ? `<span class="sug-resposta-autor">por ${admEscapar(s.respondidoPor)}${s.dataResposta ? ` · ${admFormatarData(s.dataResposta)}` : ""}</span>` : ""}
      </div>`
          : ""
      }

      ${
        estaRespondendo
          ? `<div class="sug-resposta-form">
        <textarea class="sug-resposta-campo" rows="3" placeholder="Escreva a resposta que o cliente vai ver…" oninput="textoResposta = this.value" autofocus>${admEscapar(textoResposta)}</textarea>
        <div class="sug-resposta-acoes">
          <button type="button" class="btn-acao" onclick="sugCancelarResposta()" ${estaEnviando ? "disabled" : ""}>Cancelar</button>
          <button type="button" class="btn-acao adm-btn-principal" onclick="sugEnviarResposta(${s.id})" ${estaEnviando ? "disabled" : ""}>${estaEnviando ? "Enviando…" : "Enviar resposta"}</button>
        </div>
      </div>`
          : ""
      }

      ${
        acoes.length > 0 || (!s.resposta && !estaRespondendo)
          ? `<div class="sug-card-acoes">
        ${!s.resposta && !estaRespondendo ? `<button type="button" class="btn-acao" onclick="sugAbrirResposta(${s.id})">Responder</button>` : ""}
        ${acoes
          .map(
            (destino) => `
          <button type="button" class="btn-acao${destino === "recusado" ? " vermelho" : destino === "implementado" ? " verde" : ""}" ${estaSalvando ? "disabled" : ""} onclick="sugMudarStatus(${s.id}, '${destino}')">
            ${destino === "pendente" ? "Reabrir" : admLabelStatus(destino)}
          </button>`,
          )
          .join("")}
      </div>`
          : ""
      }
    </li>`;
}

function renderizarPaginacao(totalPaginas) {
  const nav = document.getElementById("paginacao");
  if (totalPaginas <= 1) {
    nav.hidden = true;
    return;
  }
  nav.hidden = false;
  document.getElementById("paginacaoInfo").textContent = `${pagina} / ${totalPaginas}`;
  document.getElementById("btnPaginaAnterior").disabled = pagina === 1;
  document.getElementById("btnPaginaProxima").disabled = pagina === totalPaginas;
}

function atualizarBotaoExportar() {
  const btn = document.getElementById("btnExportarCsv");
  btn.textContent = podeExportar ? "Exportar CSV" : "Exportar CSV 🔒";
  btn.title = podeExportar ? "" : "Disponível no plano Pro";
}

function sugAbrirResposta(id) {
  const s = sugestoes.find((x) => x.id === id);
  respondendoId = id;
  textoResposta = s?.resposta || "";
  renderizar();
}

function sugCancelarResposta() {
  respondendoId = null;
  textoResposta = "";
  renderizar();
}

async function sugEnviarResposta(id) {
  const idAdmin = localStorage.getItem("idUsuario");
  enviandoRespostaId = id;
  renderizar();
  try {
    const dados = await admResponderSugestao(id, { idAdmin, resposta: textoResposta });
    const salva = dados.avaliacao || dados;
    sugestoes = sugestoes.map((s) =>
      s.id === id
        ? { ...s, resposta: salva.resposta, respondidoPor: salva.respondidoPor, dataResposta: salva.dataResposta }
        : s,
    );
    mostrarToast("Resposta enviada.");
    respondendoId = null;
    textoResposta = "";
  } catch (e) {
    mostrarToast(e.message || "Não foi possível enviar a resposta.", true);
  } finally {
    enviandoRespostaId = null;
    renderizar();
  }
}

async function sugMudarStatus(id, novo) {
  const sugestao = sugestoes.find((s) => s.id === id);
  if (!sugestao) return;
  const anterior = { status: sugestao.status, statusUi: sugestao.statusUi };
  salvandoId = id;
  // atualização otimista — a lista responde na hora
  sugestoes = sugestoes.map((s) => (s.id === id ? { ...s, status: novo, statusUi: novo } : s));
  renderizar();
  try {
    await admAtualizarStatusSugestao(id, novo);
    mostrarToast(`Marcada como "${admLabelStatus(novo)}".`);
  } catch (e) {
    // desfaz se a API recusar
    sugestoes = sugestoes.map((s) => (s.id === id ? { ...s, ...anterior } : s));
    mostrarToast(`Não foi possível atualizar: ${e.message}`, true);
  } finally {
    salvandoId = null;
    renderizar();
  }
}

function exportarCsv() {
  if (!podeExportar) {
    mostrarToast("Exportar em CSV está disponível no plano Pro.", true);
    return;
  }
  const filtradas = sugestoesFiltradas();
  if (filtradas.length === 0) {
    mostrarToast("Nada para exportar com esse filtro.", true);
    return;
  }
  const cabecalho = ["id", "status", "nota", "categoria", "estabelecimento", "autor", "data", "comentario"];
  const escapar = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
  const linhas = filtradas.map((s) =>
    [
      s.id,
      admLabelStatus(s.statusUi),
      s.nota ?? "",
      s.categoria ?? "",
      s.estabelecimento ?? "",
      s.autor ?? "",
      s.dataAvaliacao ?? "",
      s.comentario ?? "",
    ]
      .map(escapar)
      .join(","),
  );
  const csv = [cabecalho.join(","), ...linhas].join("\n");
  const url = URL.createObjectURL(new Blob([`﻿${csv}`], { type: "text/csv" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = `suggesto-sugestoes-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
  mostrarToast(`${filtradas.length} linhas exportadas.`);
}

let toastTimeout;
function mostrarToast(texto, erro = false) {
  const toast = document.getElementById("toast");
  toast.textContent = texto;
  toast.classList.toggle("toast-erro", erro);
  toast.classList.add("visivel");
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => toast.classList.remove("visivel"), 2500);
}
