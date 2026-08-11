const API_BASE = "http://localhost:8080/api";
const PLACEHOLDER_ESTABELECIMENTO = "imagens/placeholder-local.png";

let saldoAtual = 0;
let resgateAtual = { id: null, nome: "", custo: 0 };
let recompensasCache = [];

function urlFotoEstabelecimento(fotoPath) {
  const nome = fotoPath ? String(fotoPath).trim() : "";
  if (!nome) return PLACEHOLDER_ESTABELECIMENTO;
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${API_BASE.replace("/api", "")}/uploads/${relativo}`;
}

document.addEventListener("DOMContentLoaded", () => {
  const idUsuario = localStorage.getItem("idUsuario");
  if (!idUsuario) {
    window.location.href = "login.html";
    return;
  }

  carregarDadosUsuario();
  carregarRecompensas();

  if (window.location.hash === "#historico") {
    mostrarAbaPontos("historico");
  }
});

function obterIdUsuario() {
  const raw = localStorage.getItem("idUsuario") ?? sessionStorage.getItem("idUsuario");
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

function normalizarPlanoFidelidade(nomePlano) {
  const chave = (nomePlano || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (chave.includes("ouro") || chave.includes("gold")) return "ouro";
  if (chave.includes("prata") || chave.includes("silver")) return "prata";
  if (chave.includes("bronze")) return "bronze";
  return "bronze";
}

function aplicarTemaPlano(nomePlano) {
  const painel = document.getElementById("painelSaldo");
  if (!painel) return;

  painel.classList.remove("plano-bronze", "plano-prata", "plano-ouro");
  painel.classList.add(`plano-${normalizarPlanoFidelidade(nomePlano)}`);
}

async function carregarDadosUsuario() {
  const idUsuario = obterIdUsuario();
  if (!idUsuario) return;

  try {
    const resposta = await fetch(`${API_BASE}/usuarios/${idUsuario}`);
    if (!resposta.ok) throw new Error("Erro ao buscar usuário.");

    const usuario = await resposta.json();
    saldoAtual = Number(usuario.pontos) || 0;

    if (usuario.nome) {
      localStorage.setItem("nomeUsuario", usuario.nome);
      atualizarSidebar(usuario.nome);
    }

    atualizarPainelSaldo(saldoAtual);
    atualizarEstatisticasUsuario(usuario);
    aplicarTemaPlano(usuario.nomePlano);
  } catch (error) {
    console.error("Erro ao carregar pontos:", error);
    mostrarToast("Não foi possível carregar seu saldo de pontos.");
  }
}

function atualizarEstatisticasUsuario(usuario) {
  const totalSugestoes = Number(usuario.totalSugestoes) || 0;
  const totalResgates = Number(usuario.totalResgates) || 0;

  const elSugestoes = document.getElementById("estatSugestoes");
  const elResgates = document.getElementById("estatResgates");

  if (elSugestoes) elSugestoes.textContent = totalSugestoes;
  if (elResgates) elResgates.textContent = totalResgates;

  const elNivel = document.getElementById("estatNivel");
  if (elNivel && usuario.nomePlano) elNivel.textContent = usuario.nomePlano;
}

function atualizarSidebar(nome) {
  const elNome = document.getElementById("sidebarNome");
  const elAvatar = document.getElementById("sidebarAvatar");
  if (elNome) elNome.textContent = nome;
  if (elAvatar) {
    const partes = nome.trim().split(/\s+/);
    let iniciais = partes[0].charAt(0).toUpperCase();
    if (partes.length > 1) iniciais += partes[partes.length - 1].charAt(0).toUpperCase();
    elAvatar.textContent = iniciais;
  }
}

function atualizarPainelSaldo(pontos) {
  const prog = calcularProgressoNivel(pontos);

  const elSaldo = document.getElementById("saldoPontos");
  if (elSaldo) elSaldo.textContent = formatarPontos(pontos);

  const elNivel = document.getElementById("estatNivel");
  if (elNivel) elNivel.textContent = prog.atual.nome;

  const elDica = document.getElementById("saldoDica");
  if (elDica) {
    elDica.innerHTML = prog.proximo
      ? `Próximo nível: ${prog.proximo.nome} (Faltam ${formatarPontos(prog.faltaParaProximo)} pts)`
      : `Nível máximo: ${prog.atual.nome}`;
  }

  const barra = document.getElementById("saldoBarraProgresso");
  if (barra) barra.style.width = `${prog.percentual}%`;

  const meta = document.getElementById("saldoMeta");
  if (meta) {
    meta.textContent = prog.metaProximo
      ? `${formatarPontos(prog.metaProximo)} pts`
      : "Nível máximo";
  }
}

async function carregarRecompensas() {
  const area = document.getElementById("mercadoArea");
  if (!area) return;

  try {
    const resposta = await fetch(`${API_BASE}/recompensas`);
    if (!resposta.ok) throw new Error("Erro ao listar recompensas.");

    recompensasCache = await resposta.json();
    renderizarMercado(recompensasCache);
  } catch (error) {
    console.error("Erro ao carregar recompensas:", error);
    area.innerHTML = `
      <p style="color:rgba(240,240,248,0.6);text-align:center;padding:40px;grid-column:1/-1">
        Não foi possível carregar as recompensas.
      </p>`;
  }
}

function faixaParaCusto(custo) {
  if (custo <= 6000) return 6000;
  if (custo <= 18000) return 18000;
  if (custo <= 25000) return 25000;
  if (custo <= 45000) return 45000;
  return 999999;
}

function tituloFaixa(faixa) {
  const mapa = {
    6000: "Até 6.000 pts",
    18000: "Até 18.000 pts",
    25000: "Até 25.000 pts",
    45000: "Até 45.000 pts",
    999999: "Acima de 45.000 pts"
  };
  return mapa[faixa] || "Recompensas";
}

function renderizarMercado(lista) {
  const area = document.getElementById("mercadoArea");
  const vazio = document.getElementById("mercadoVazio");
  if (!area) return;

  area.innerHTML = "";

  if (!lista.length) {
    vazio?.classList.add("visivel");
    return;
  }

  vazio?.classList.remove("visivel");

  const porFaixa = {};
  lista.forEach((rec) => {
    const custo = Number(rec.custoPontos) || 0;
    const faixa = faixaParaCusto(custo);
    if (!porFaixa[faixa]) porFaixa[faixa] = [];
    porFaixa[faixa].push(rec);
  });

  Object.keys(porFaixa)
    .map(Number)
    .sort((a, b) => a - b)
    .forEach((faixa) => {
      const itens = porFaixa[faixa];
      const secao = document.createElement("section");
      secao.className = "recomp-secao";
      secao.dataset.faixa = String(faixa);

      secao.innerHTML = `
        <div class="secao-topo">
          <div class="secao-titulo-wrap">
            <h2 class="secao-titulo">${tituloFaixa(faixa)}</h2>
          </div>
          <span class="secao-count">${itens.length} recompensa${itens.length !== 1 ? "s" : ""}</span>
        </div>
        <div class="recomp-grade"></div>
      `;

      const grade = secao.querySelector(".recomp-grade");
      itens.forEach((rec) => grade.appendChild(criarCardRecompensa(rec)));
      area.appendChild(secao);
    });
}

function criarCardRecompensa(rec) {
  const custo = Number(rec.custoPontos) || 0;
  const nome = rec.nome || "Recompensa";
  const desc = rec.descricao || "";
  const estabNome = rec.estabelecimento?.nome || "Parceiro";
  // Foto própria da recompensa quando o admin definiu uma; senão, a do estabelecimento.
  const fotoUrl = urlFotoEstabelecimento(rec.fotoPath || rec.estabelecimento?.fotoPath);
  const bloqueado = custo > saldoAtual;

  const card = document.createElement("div");
  card.className = "recomp-card";
  card.dataset.custo = String(custo);
  card.dataset.id = String(rec.id);

  card.innerHTML = `
    <div class="recomp-imagem">
      <img class="recomp-foto" src="${fotoUrl}" alt="${estabNome}" />
      <div class="recomp-overlay"></div>
      <span class="recomp-estabelecimento">${estabNome}</span>
    </div>
    <div class="recomp-corpo">
      <div class="recomp-custo">
        <i class="fas fa-star"></i>
        <span>${formatarPontos(custo)} pts</span>
      </div>
      <h3 class="recomp-nome">${nome}</h3>
      <p class="recomp-desc">${desc}</p>
      <button type="button" class="recomp-btn${bloqueado ? " recomp-btn-bloqueado" : ""}" ${bloqueado ? "disabled" : ""}>
        ${bloqueado ? "Pontos insuficientes" : "Resgatar"}
      </button>
    </div>
  `;

  const img = card.querySelector(".recomp-foto");
  if (img) {
    img.onerror = function () {
      this.onerror = null;
      this.src = PLACEHOLDER_ESTABELECIMENTO;
    };
  }

  const btn = card.querySelector(".recomp-btn");
  if (!bloqueado) {
    btn.addEventListener("click", () => abrirResgate(rec.id, nome, custo));
  }

  return card;
}

function filtrarRecompensas() {
  const busca = document.getElementById("campoBusca")?.value.toLowerCase() || "";
  const cards = document.querySelectorAll(".recomp-card");
  const secoes = document.querySelectorAll(".recomp-secao");
  const vazio = document.getElementById("mercadoVazio");
  let totalVisivel = 0;

  secoes.forEach((secao) => {
    let visivelNaSecao = 0;
    secao.querySelectorAll(".recomp-card").forEach((card) => {
      const nome = card.querySelector(".recomp-nome")?.textContent.toLowerCase() || "";
      const estab = card.querySelector(".recomp-estabelecimento")?.textContent.toLowerCase() || "";
      const desc = card.querySelector(".recomp-desc")?.textContent.toLowerCase() || "";
      const visivel = nome.includes(busca) || estab.includes(busca) || desc.includes(busca);
      card.style.display = visivel ? "" : "none";
      if (visivel) visivelNaSecao++;
    });
    secao.style.display = visivelNaSecao === 0 ? "none" : "";
    totalVisivel += visivelNaSecao;
  });

  vazio?.classList.toggle("visivel", totalVisivel === 0 && cards.length > 0);
}

function filtrarFaixa(botao, limite) {
  document.querySelectorAll(".faixa-btn").forEach((b) => b.classList.remove("faixa-btn-ativa"));
  botao.classList.add("faixa-btn-ativa");

  const secoes = document.querySelectorAll(".recomp-secao");
  const vazio = document.getElementById("mercadoVazio");
  let totalVisivel = 0;

  secoes.forEach((secao) => {
    const faixaSecao = parseInt(secao.dataset.faixa, 10);
    const mostrar = faixaSecao <= limite;
    secao.style.display = mostrar ? "" : "none";
    if (mostrar) totalVisivel += secao.querySelectorAll(".recomp-card:not([style*=\"none\"])").length;
  });

  document.getElementById("campoBusca").value = "";
  vazio?.classList.toggle("visivel", totalVisivel === 0);
}

function abrirResgate(recompensaId, nome, custo) {
  if (custo > saldoAtual) {
    mostrarToast("Pontos insuficientes para este resgate");
    return;
  }

  resgateAtual = { id: recompensaId, nome, custo };

  document.getElementById("modalRecompNome").textContent = nome;
  document.getElementById("modalRecompCusto").textContent = formatarPontos(custo) + " pts";
  document.getElementById("modalCustoValor").textContent = "- " + formatarPontos(custo) + " pts";
  document.getElementById("modalSaldoAtual").textContent = formatarPontos(saldoAtual) + " pts";
  document.getElementById("modalSaldoFinal").textContent = formatarPontos(saldoAtual - custo) + " pts";

  document.getElementById("modalCupomSucesso").style.display = "none";
  document.getElementById("modalAcoesResgate").style.display = "";

  document.getElementById("modalResgate").classList.add("aberto");
}

function fecharModal() {
  document.getElementById("modalResgate").classList.remove("aberto");
}

document.getElementById("modalResgate")?.addEventListener("click", (e) => {
  if (e.target === e.currentTarget) fecharModal();
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") fecharModal();
});

async function confirmarResgate() {
  const idUsuario = obterIdUsuario();
  if (!idUsuario || !resgateAtual.id) return;

  try {
    const resposta = await fetch(`${API_BASE}/resgates`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        usuarioId: idUsuario,
        recompensaId: resgateAtual.id
      })
    });

    const dados = await resposta.json();
    if (!resposta.ok) {
      throw new Error(dados.message || "Erro ao resgatar.");
    }

    const saldoAnterior = saldoAtual;
    saldoAtual = Number(dados.novoSaldo) || 0;

    document.getElementById("modalCodigoCupom").textContent = dados.codigoCupom || "—";
    document.getElementById("modalCupomSucesso").style.display = "block";
    document.getElementById("modalAcoesResgate").style.display = "none";

    const elSaldo = document.getElementById("saldoPontos");
    if (elSaldo) animarContador(elSaldo, saldoAnterior, saldoAtual, 800);

    atualizarPainelSaldo(saldoAtual);
    renderizarMercado(recompensasCache);
    carregarDadosUsuario();

    mostrarToast(`Resgate de "${resgateAtual.nome}" realizado! Cupom: ${dados.codigoCupom}`);
  } catch (error) {
    console.error("Erro no resgate:", error);
    mostrarToast(error.message || "Não foi possível concluir o resgate.");
  }
}

function mostrarToast(mensagem) {
  const toast = document.getElementById("toast");
  document.getElementById("toastMsg").textContent = mensagem;
  toast.classList.add("visivel");
  setTimeout(() => toast.classList.remove("visivel"), 3200);
}

function animarContador(el, de, ate, duracao) {
  const inicio = performance.now();
  function passo(agora) {
    const progresso = Math.min((agora - inicio) / duracao, 1);
    const easeOut = 1 - Math.pow(1 - progresso, 3);
    const atual = Math.round(de + (ate - de) * easeOut);
    el.textContent = formatarPontos(atual);
    if (progresso < 1) requestAnimationFrame(passo);
  }
  requestAnimationFrame(passo);
}

// ── ABAS: LOJA / HISTÓRICO ──────────────────────────────────────────────
const PONTOS_SUGESTAO_ACEITA = 500;
let historicoCarregado = false;

function mostrarAbaPontos(aba) {
  const ehHistorico = aba === "historico";

  document.getElementById("abaLoja")?.classList.toggle("ativa", !ehHistorico);
  document.getElementById("abaHistorico")?.classList.toggle("ativa", ehHistorico);
  document.getElementById("secaoLoja").style.display = ehHistorico ? "none" : "";
  document.getElementById("secaoHistorico").style.display = ehHistorico ? "" : "none";

  if (ehHistorico && !historicoCarregado) {
    carregarHistorico();
  }
}

async function carregarHistorico() {
  const idUsuario = obterIdUsuario();
  const lista = document.getElementById("historicoLista");
  const vazio = document.getElementById("historicoVazio");
  if (!idUsuario || !lista) return;

  try {
    const [resgates, avaliacoes] = await Promise.all([
      fetch(`${API_BASE}/resgates/usuario/${idUsuario}`).then((r) => (r.ok ? r.json() : [])),
      fetch(`${API_BASE}/avaliacoes/usuario/${idUsuario}`).then((r) => (r.ok ? r.json() : [])),
    ]);

    const movimentos = [
      ...(Array.isArray(resgates) ? resgates : []).map((r) => ({
        tipo: "resgate",
        data: r.dataResgate,
        titulo: r.nomeRecompensa || "Recompensa",
        sub: r.estabelecimento || "",
        pontos: -(Number(r.custoPontos) || 0),
        codigoCupom: r.codigoCupom,
      })),
      ...(Array.isArray(avaliacoes) ? avaliacoes : [])
        .filter((a) => typeof isStatusAprovado === "function" && isStatusAprovado(a.status))
        .map((a) => ({
          tipo: "sugestao",
          data: a.dataAvaliacao,
          titulo: "Sugestão aprovada",
          sub: a.estabelecimento?.nome || "",
          pontos: PONTOS_SUGESTAO_ACEITA,
        })),
    ].sort((a, b) => new Date(b.data || 0) - new Date(a.data || 0));

    historicoCarregado = true;

    if (!movimentos.length) {
      lista.innerHTML = "";
      vazio?.classList.add("visivel");
      return;
    }

    vazio?.classList.remove("visivel");
    lista.innerHTML = movimentos.map(renderizarItemHistorico).join("");
  } catch (error) {
    console.error("Erro ao carregar histórico de pontos:", error);
    vazio?.classList.add("visivel");
  }
}

function renderizarItemHistorico(mov) {
  const positivo = mov.pontos >= 0;
  const dataFormatada = formatarDataHistorico(mov.data);
  const sinal = positivo ? "+" : "";

  return `
    <li class="historico-item historico-item-${positivo ? "credito" : "debito"}">
      <div class="historico-icone">
        <i class="fas ${mov.tipo === "resgate" ? "fa-gift" : "fa-paper-plane"}"></i>
      </div>
      <div class="historico-info">
        <span class="historico-titulo">${mov.titulo}</span>
        <span class="historico-sub">${[mov.sub, mov.codigoCupom].filter(Boolean).join(" · ") || dataFormatada}</span>
      </div>
      <div class="historico-valores">
        <span class="historico-pontos">${sinal}${formatarPontos(mov.pontos)} pts</span>
        <span class="historico-data">${dataFormatada}</span>
      </div>
    </li>`;
}

function formatarDataHistorico(iso) {
  if (!iso) return "";
  const data = new Date(iso);
  if (Number.isNaN(data.getTime())) return "";
  return data.toLocaleDateString("pt-BR", { day: "2-digit", month: "short", year: "numeric" });
}

function abrirModalSair() {
  document.getElementById("modalSaida")?.classList.add("aberto");
}

function fecharModalSaida(id) {
  document.getElementById(id)?.classList.remove("aberto");
}

function confirmarSair() {
  localStorage.clear();
  window.location.href = "login.html";
}
