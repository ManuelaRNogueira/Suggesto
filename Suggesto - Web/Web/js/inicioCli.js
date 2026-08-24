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
  carregarEstabelecimentos();
  carregarRecomendados();
  carregarDestaques();
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

function escaparHtml(texto) {
  const div = document.createElement("div");
  div.textContent = texto ?? "";
  return div.innerHTML;
}

// Destaque de posts: sugestões recentes de clientes que já subiram de nível.
// É o benefício visível de chegar a Ouro/Platina.
async function carregarDestaques() {
  const secao = document.getElementById("destaquesSecao");
  const grade = document.getElementById("destaquesGrade");
  if (!secao || !grade) return;

  try {
    const resposta = await fetch(`${API_BASE}/avaliacoes/destaques`);
    if (!resposta.ok) return;

    const destaques = await resposta.json();
    if (!Array.isArray(destaques) || destaques.length === 0) return;

    grade.innerHTML = destaques
      .map((a) => {
        const autor = a.usuario?.nome || "Cliente";
        const nivel = a.usuario?.nivel || "ouro";
        const nivelNome = a.usuario?.nivelNome || "Ouro";
        const local = a.estabelecimento?.nome || "Estabelecimento";
        const nota = Number(a.nota) || 0;
        const estrelas = Array.from(
          { length: 5 },
          (_, i) => `<i class="fas fa-star${i < nota ? "" : " vazia"}"></i>`,
        ).join("");

        return `
          <article class="destaque-card destaque-${nivel}">
            <div class="destaque-topo">
              <span class="destaque-avatar">${escaparHtml(autor.charAt(0).toUpperCase())}</span>
              <div class="destaque-autor-info">
                <span class="destaque-autor">${escaparHtml(autor)}</span>
                <span class="destaque-local">${escaparHtml(local)}</span>
              </div>
              <span class="destaque-nivel nivel-${nivel}">${escaparHtml(nivelNome)}</span>
            </div>
            <div class="destaque-estrelas">${estrelas}</div>
            <p class="destaque-texto">${escaparHtml(a.comentario || "")}</p>
          </article>`;
      })
      .join("");

    secao.style.display = "";
  } catch (error) {
    console.error("Erro ao carregar destaques:", error);
  }
}

// Recomendação por proximidade: estabelecimentos da mesma cidade do cliente.
// Quando não há nada para mostrar, a seção continua visível com uma explicação —
// sumir sem aviso passava a impressão de que a funcionalidade estava quebrada.
async function carregarRecomendados() {
  const secao = document.getElementById("recomendadosSecao");
  const grade = document.getElementById("recomendadosGrade");
  const vazio = document.getElementById("recomendadosVazio");
  const idUsuario = obterIdUsuario();
  if (!secao || !grade || !idUsuario) return;

  try {
    const resposta = await fetch(
      `${API_BASE}/estabelecimentos/recomendados?idUsuario=${idUsuario}`,
    );
    if (!resposta.ok) return;

    const dados = await resposta.json();
    const estabelecimentos = Array.isArray(dados.estabelecimentos)
      ? dados.estabelecimentos
      : [];
    const cidade = dados.cidade;

    const rotuloCidade = document.getElementById("recomendadosCidade");
    if (rotuloCidade) rotuloCidade.textContent = cidade || "";

    grade.innerHTML = "";

    if (estabelecimentos.length === 0) {
      if (vazio) {
        // Sem cidade é conta antiga, criada antes do endereço virar obrigatório.
        vazio.querySelector("p").textContent = cidade
          ? "Nenhum local cadastrado na sua cidade ainda"
          : "Preencha seu endereço no perfil para recomendarmos os melhores locais da sua região";
        vazio.classList.add("visivel");
      }
      secao.style.display = "";
      return;
    }

    if (vazio) vazio.classList.remove("visivel");

    estabelecimentos
      .slice(0, 6)
      .forEach((estab) => grade.appendChild(criarCardEstabelecimento(estab, opcoesCardCliente)));

    secao.style.display = "";
  } catch (error) {
    console.error("Erro ao carregar recomendados:", error);
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
      grade.appendChild(criarCardEstabelecimento(estab, opcoesCardCliente));
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
