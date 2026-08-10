// Resumo administrativo do web: leitura apenas, dados reais da API.
// Nenhuma ação de gestão aqui — isso é do app desktop.

const FAIXAS = [
  { id: "pendente", chave: "pendentes", desc: "Aguardando triagem" },
  { id: "implementado", chave: "implementados", desc: "Aprovadas e executadas" },
  { id: "recusado", chave: "recusados", desc: "Não aprovadas" },
];

document.addEventListener("DOMContentLoaded", () => {
  if (!admVerificarSessao()) return;
  montarConta();
  carregar();

  document.getElementById("btnSair").addEventListener("click", () => {
    if (!confirm("Encerrar sessão?")) return;
    localStorage.clear();
    window.location.href = "login.html";
  });

  const modal = document.getElementById("modalDesktop");

  document.querySelectorAll("[data-desktop-only]").forEach(item => {
    item.addEventListener("click", e => {
      e.preventDefault();
      modal.classList.add("aberto");
    });
  });

  document.getElementById("btnFecharDesktop").addEventListener("click", () => {
    modal.classList.remove("aberto");
  });

  modal.addEventListener("click", e => {
    if (e.target === modal) modal.classList.remove("aberto");
  });
});

function montarConta() {
  const nome = localStorage.getItem("nomeUsuario") || "Administrador";
  const email = localStorage.getItem("emailUsuario") || "";
  document.getElementById("contaNome").textContent = nome;
  document.getElementById("contaAvatar").textContent = admIniciais(nome);
  if (email) document.getElementById("contaEmail").textContent = email;
}

let estabelecimentosCache = [];

async function carregar() {
  try {
    const estabelecimentos = await admBuscarEstabelecimentos().catch(() => []);
    estabelecimentosCache = estabelecimentos || [];
    validarSelecaoLocal(estabelecimentosCache);

    const metricas = await admBuscarMetricas();
    renderar(metricas, estabelecimentosCache);
  } catch (e) {
    const alvo = document.getElementById("erro");
    alvo.textContent =
      `Não foi possível carregar os dados (${e.message}). ` +
      "Verifique se a API está rodando em localhost:8080.";
    alvo.hidden = false;
    document.getElementById("resumoSub").textContent = "Sem conexão com a API";
  }
}

// Se o local escolhido anteriormente não pertence mais a este gerente, limpa a seleção.
function validarSelecaoLocal(estabelecimentos) {
  const selecionado = admEstabelecimentoSelecionado();
  if (!selecionado) return;
  const existe = estabelecimentos.some(e => String(e.id) === String(selecionado));
  if (!existe) admDefinirEstabelecimentoSelecionado(null);
}

async function selecionarLocal(id) {
  if (id === null) {
    admDefinirEstabelecimentoSelecionado(null);
  } else {
    const atual = admEstabelecimentoSelecionado();
    admDefinirEstabelecimentoSelecionado(atual === String(id) ? null : id);
  }
  renderarLocais(estabelecimentosCache);

  try {
    const metricas = await admBuscarMetricas();
    renderar(metricas, estabelecimentosCache);
  } catch (e) {
    const alvo = document.getElementById("erro");
    alvo.textContent =
      `Não foi possível carregar os dados (${e.message}). ` +
      "Verifique se a API está rodando em localhost:8080.";
    alvo.hidden = false;
  }
}

function renderar(metricas, estabelecimentos) {
  const total = metricas.totalSugestoes || 0;

  document.getElementById("resumoSub").textContent =
    `${total} ${total === 1 ? "sugestão recebida" : "sugestões recebidas"} · ` +
    `${metricas.totalEstabelecimentos || 0} ` +
    `${metricas.totalEstabelecimentos === 1 ? "local" : "locais"}`;

  const faixas = FAIXAS.map(f => {
    const qtd = metricas[f.chave] || 0;
    return { ...f, qtd, pct: total ? (qtd / total) * 100 : 0 };
  });

  renderarKpis(metricas, faixas, total);
  renderarStatus(faixas, total);
  renderarRecentes(metricas.sugestoesRecentes || []);
  renderarCategorias(metricas.porCategoria || {});
  renderarLocais(estabelecimentos || []);
}

function renderarKpis(metricas, faixas, total) {
  const destaque = `
    <div class="kpi kpi-destaque">
      <p class="kpi-rot">Novas nos últimos 7 dias</p>
      <p class="kpi-val">${metricas.novasSemana || 0}</p>
      <p class="kpi-sub">de ${total} no total</p>
    </div>`;

  const demais = faixas
    .map(f => `
      <div class="kpi st-${f.id}">
        <p class="kpi-rot">${admLabelStatus(f.id)}</p>
        <p class="kpi-val">${f.qtd}</p>
        <p class="kpi-sub">${f.pct.toFixed(1)}% do total</p>
      </div>`)
    .join("");

  document.getElementById("kpis").innerHTML = destaque + demais;
}

function renderarStatus(faixas, total) {
  document.getElementById("totalNota").textContent = `${total} no total`;

  document.getElementById("barra").innerHTML = total === 0
    ? ""
    : faixas
        .filter(f => f.qtd > 0)
        .map(f => `<span class="barra-parte st-${f.id}" style="width:${f.pct}%"
                     title="${admLabelStatus(f.id)}: ${f.qtd}"></span>`)
        .join("");

  document.getElementById("status").innerHTML = faixas
    .map(f => `
      <li class="status-item st-${f.id}">
        <span class="pill">${admLabelStatus(f.id)}</span>
        <span class="status-desc">${f.desc}</span>
        <span class="status-num">${f.qtd}</span>
      </li>`)
    .join("");
}

function renderarRecentes(lista) {
  const alvo = document.getElementById("recentes");
  if (lista.length === 0) {
    alvo.innerHTML = "";
    return;
  }

  alvo.innerHTML = lista.slice(0, 5).map(s => {
    const meta = [s.categoria, s.estabelecimento, s.autor].filter(Boolean).join(" · ");
    return `
      <li class="recente st-${s.statusUi}">
        <div class="recente-topo">
          <span class="pill">${admLabelStatus(s.statusUi)}</span>
          <span class="recente-tempo">${admFormatarData(s.dataAvaliacao)}</span>
        </div>
        <p class="recente-txt">${admEscapar(admTituloSugestao(s.comentario))}</p>
        <p class="recente-meta">${admEscapar(meta) || "—"}</p>
      </li>`;
  }).join("");
}

function renderarCategorias(mapa) {
  const lista = Object.entries(mapa).sort((a, b) => b[1] - a[1]).slice(0, 5);
  const alvo = document.getElementById("categorias");

  if (lista.length === 0) {
    alvo.innerHTML = `<li class="vazio">Sem categorias registradas.</li>`;
    return;
  }

  const maior = lista[0][1] || 1;
  alvo.innerHTML = lista.map(([nome, qtd]) => `
    <li class="cat">
      <div class="cat-topo">
        <span>${admEscapar(nome)}</span>
        <span class="cat-num">${qtd}</span>
      </div>
      <span class="cat-trilho"><span class="cat-fill" style="width:${(qtd / maior) * 100}%"></span></span>
    </li>`).join("");
}

function renderarLocais(lista) {
  const alvo = document.getElementById("locais");
  if (lista.length === 0) {
    alvo.innerHTML = `<li class="vazio">Nenhum estabelecimento vinculado.</li>`;
    return;
  }

  const selecionado = admEstabelecimentoSelecionado();

  const itemTodos = `
    <li class="local local-clicavel${selecionado ? "" : " selecionado"}"
        role="button" tabindex="0"
        onclick="selecionarLocal(null)"
        onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();selecionarLocal(null);}">
      <span class="local-info">
        <span class="local-nome">Todos os locais</span>
        <span class="local-meta">Resumo combinado</span>
      </span>
    </li>`;

  const itensLocais = lista.slice(0, 6).map(e => `
    <li class="local local-clicavel${String(e.id) === selecionado ? " selecionado" : ""}"
        role="button" tabindex="0"
        onclick="selecionarLocal(${e.id})"
        onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();selecionarLocal(${e.id});}">
      <span class="local-info">
        <span class="local-nome">${admEscapar(e.nome)}</span>
        <span class="local-meta">${admEscapar(e.cidade || "—")}</span>
      </span>
      <span class="local-num" title="Sugestões recebidas">${e.totalSugestoes ?? 0}</span>
      <span class="local-tag${e.ativo === 1 ? " ativo" : ""}">${e.ativo === 1 ? "Ativo" : "Inativo"}</span>
    </li>`).join("");

  alvo.innerHTML = itemTodos + itensLocais;
}
