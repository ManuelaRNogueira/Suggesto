const API_BASE_URL = "http://localhost:8080/api/avaliacoes";

let todasAsSugestoes = [];
let filtrosAtuais = {
  texto: "",
  tipo: "todos",
  categoria: "todos",
  status: "todos",
};

document.addEventListener("DOMContentLoaded", () => {
  carregarDadosUsuario();
  carregarSugestoesDoUsuario();

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") carregarSugestoesDoUsuario();
  });
});

async function carregarSugestoesDoUsuario() {
  const idUsuario = localStorage.getItem("idUsuario");
  if (!idUsuario) {
    window.location.href = "login.html";
    return;
  }

  try {
    const resposta = await fetch(`${API_BASE_URL}/usuario/${idUsuario}`);

    if (!resposta.ok) {
      throw new Error(`Falha no servidor. Status: ${resposta.status}`);
    }

    todasAsSugestoes = await resposta.json();

    atualizarResumo(todasAsSugestoes);
    aplicarFiltros();
  } catch (erro) {
    console.error("Erro na requisição da API:", erro);
    document.getElementById("sugestoesList").innerHTML = `
            <div style="text-align: center; padding: 40px; color: #f87171;">
                <p>Erro ao carregar as sugestões. Verifique o console.</p>
            </div>`;
  }
}

function aplicarFiltros() {
  filtrosAtuais.texto = document
    .getElementById("campoBusca")
    .value.toLowerCase()
    .trim();

  document.getElementById("btnLimparBusca").style.display = filtrosAtuais.texto
    ? "block"
    : "none";

  const listaFiltrada = todasAsSugestoes.filter((sugestao) => {
    const nomeLoja = (
      sugestao.estabelecimento ? sugestao.estabelecimento.nome : ""
    ).toLowerCase();
    const comentario = (sugestao.comentario || "").toLowerCase();
    const passaTexto =
      nomeLoja.includes(filtrosAtuais.texto) ||
      comentario.includes(filtrosAtuais.texto);

    const tipoNoBanco = (sugestao.tipo || "").toLowerCase();
    const passaTipo =
      filtrosAtuais.tipo === "todos" || tipoNoBanco === filtrosAtuais.tipo;

    const catEstab = slugCategoriaEstabelecimento(
      sugestao.estabelecimento?.categoria
    );
    const passaCat =
      filtrosAtuais.categoria === "todos" ||
      catEstab === filtrosAtuais.categoria;

    const passaStatus =
      filtrosAtuais.status === "todos" ||
      chaveStatus(sugestao.status) === filtrosAtuais.status;

    return passaTexto && passaTipo && passaCat && passaStatus;
  });

  renderizarLista(listaFiltrada);

  const textoResultados = document.getElementById("resultadosTexto");
  const btnLimpar = document.getElementById("btnLimparTudo");

  textoResultados.innerText = `${listaFiltrada.length} sugestões encontradas`;

  const temFiltro =
    filtrosAtuais.texto ||
    filtrosAtuais.tipo !== "todos" ||
    filtrosAtuais.categoria !== "todos" ||
    filtrosAtuais.status !== "todos";
  btnLimpar.style.display = temFiltro ? "inline-block" : "none";
}

function filtrarTipo(botao, valor) {
  document
    .querySelectorAll(".chip-tipo")
    .forEach((b) => b.classList.remove("chip-ativo"));
  botao.classList.add("chip-ativo");
  filtrosAtuais.tipo = valor;
  aplicarFiltros();
}

function filtrarCategoria(botao, valor) {
  document
    .querySelectorAll(".chip-cat")
    .forEach((b) => b.classList.remove("chip-ativo"));
  botao.classList.add("chip-ativo");
  filtrosAtuais.categoria = valor;
  aplicarFiltros();
}

function filtrarStatus(botao, valor) {
  document
    .querySelectorAll(".chip-status")
    .forEach((b) => b.classList.remove("chip-ativo"));
  botao.classList.add("chip-ativo");
  filtrosAtuais.status = valor;
  aplicarFiltros();
}

function limparBusca() {
  document.getElementById("campoBusca").value = "";
  aplicarFiltros();
}

function limparTudo() {
  limparBusca();

  filtrosAtuais = {
    texto: "",
    tipo: "todos",
    categoria: "todos",
    status: "todos",
  };

  document
    .querySelectorAll(".chip")
    .forEach((b) => b.classList.remove("chip-ativo"));
  document
    .querySelector('.chip-tipo[onclick*="todos"]')
    .classList.add("chip-ativo");
  document
    .querySelector('.chip-cat[onclick*="todos"]')
    .classList.add("chip-ativo");
  document
    .querySelector('.chip-status[onclick*="todos"]')
    .classList.add("chip-ativo");

  aplicarFiltros();
}

function renderizarLista(sugestoes) {
  const container = document.getElementById("sugestoesList");
  const listaVazia = document.getElementById("listaVazia");

  container.innerHTML = "";

  if (sugestoes.length === 0) {
    listaVazia.style.display = "flex";
    return;
  }

  listaVazia.style.display = "none";

  sugestoes.forEach((sugestao) => {
    const statusChave = chaveStatus(sugestao.status);
    const classeCard = `sugestao-card card-status-${statusChave}`;
    const classeStatusTexto = `status-${statusChave}`;
    const textoStatus = rotuloStatus(sugestao.status);
    const icone = iconeStatus(sugestao.status);

    const tipoAtual = (sugestao.tipo || "sugestao").toLowerCase();
    const labelTipo =
      tipoAtual === "critica"
        ? "Crítica"
        : tipoAtual === "elogio"
          ? "Elogio"
          : "Sugestão";

    const dataOriginal = sugestao.dataAvaliacao
      ? sugestao.dataAvaliacao.split("T")[0]
      : new Date().toISOString().split("T")[0];
    const dataFormatada = new Date(
      dataOriginal + "T00:00:00",
    ).toLocaleDateString("pt-BR", {
      day: "2-digit",
      month: "long",
      year: "numeric",
    });

    const nomeCategoria = rotuloCategoriaAvaliacao(sugestao);
    const nomeLoja = sugestao.estabelecimento
      ? sugestao.estabelecimento.nome
      : "Estabelecimento";

    const palavras = nomeLoja.trim().split(" ");
    let letrasAvatar = palavras[0].substring(0, 1);
    if (palavras.length > 1) letrasAvatar += palavras[1].substring(0, 1);
    letrasAvatar = letrasAvatar.toUpperCase();

    const cardHTML = `
            <div class="${classeCard}" data-id="${sugestao.idAvaliacao}">
                <div class="card-faixa card-faixa-${statusChave}"></div>
                <div class="card-corpo">
                    <div class="card-topo">
                        <div class="card-esquerda">
                            <div class="card-avatar">${letrasAvatar}</div>
                            <div>
                                <h3 class="card-estabelecimento">${nomeLoja}</h3>
                                <p class="card-data"><i class="fas fa-calendar-alt"></i> ${dataFormatada}</p>
                            </div>
                        </div>
                        <div class="card-direita">
                            <span class="card-status ${classeStatusTexto}">
                                <i class="fas ${icone}"></i> ${textoStatus}
                            </span>
                        </div>
                    </div>

                    <div class="card-tags">
                        <span class="tag ${classeTagCategoria(nomeCategoria)}">
                            ${labelTipo} · ${nomeCategoria}
                        </span>
                        <div class="card-estrelas">
                            ${gerarEstrelas(sugestao.nota)}
                        </div>
                    </div>

                    <p class="card-texto">${sugestao.comentario}</p>
                </div>
            </div>
        `;

    container.insertAdjacentHTML("beforeend", cardHTML);
  });
}

function gerarEstrelas(nota) {
  let estrelas = "";
  for (let i = 1; i <= 5; i++) {
    estrelas +=
      i <= nota ? '<i class="fas fa-star"></i>' : '<i class="far fa-star"></i>';
  }
  return estrelas;
}

function atualizarResumo(sugestoes) {
  const total = sugestoes.length;
  const aprovadas = sugestoes.filter((s) => isStatusAprovado(s.status)).length;
  const pendentes = sugestoes.filter(
    (s) => chaveStatus(s.status) === "pendente",
  ).length;

  document.getElementById("totalSugestoes").innerText = total;
  document.getElementById("totalResolvidas").innerText = aprovadas;
  document.getElementById("totalPendentes").innerText = pendentes;
}

function abrirModal(idModal) {
  document.getElementById(idModal).style.display = "flex";
}
function fecharModal(idModal) {
  document.getElementById(idModal).style.display = "none";
}
function abrirSugestao() {
  window.location.href = "./fazerSugestao.html";
}

function carregarDadosUsuario() {
    const nome = localStorage.getItem('nomeUsuario') || 'Usuário';

    const elementoSaudacao = document.getElementById('saudacaoNome');
    const elementoSidebar = document.getElementById('sidebarNome');
    const elementoAvatar = document.getElementById('sidebarAvatar');

    if (elementoSaudacao)
        elementoSaudacao.innerText = `Olá, ${nome.split(' ')[0]} 👋`;

    if (elementoSidebar)
        elementoSidebar.innerText = nome;

    if (elementoAvatar)
        elementoAvatar.innerText = nome.substring(0, 2).toUpperCase();
}

function abrirModalSair() { 
    const modal = document.getElementById('modalSair');
    if (modal) modal.classList.add('aberto'); 
}

function fecharModal(id) { 
    const modal = document.getElementById(id);
    if (modal) modal.classList.remove('aberto'); 
}

function confirmarSair() { 
    localStorage.clear(); 
    window.location.href = 'login.html'; 
}
