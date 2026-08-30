// Gestão de equipe — código de acesso + solicitações pendentes. Mesmos
// endpoints usados por Solicitacoes.jsx no desktop (ver js/admApi.js).
// Só o admin principal do estabelecimento gerencia isso (o backend também
// confere isso em aceitar/recusar).

document.addEventListener("DOMContentLoaded", () => {
  if (!admVerificarSessao()) return;
  montarConta();
  carregar();

  document.getElementById("btnSair").addEventListener("click", () => {
    if (!confirm("Encerrar sessão?")) return;
    localStorage.clear();
    window.location.href = "login.html";
  });

  document.getElementById("btnCopiarCodigo").addEventListener("click", copiarCodigo);
});

function montarConta() {
  const nome = localStorage.getItem("nomeUsuario") || "Administrador";
  const email = localStorage.getItem("emailUsuario") || "";
  document.getElementById("contaNome").textContent = nome;
  document.getElementById("contaAvatar").textContent = admIniciais(nome);
  if (email) document.getElementById("contaEmail").textContent = email;

  // Busca a foto de perfil de verdade — só troca as iniciais se existir.
  const idUsuario = localStorage.getItem("idUsuario");
  if (idUsuario) {
    admBuscarUsuario(idUsuario)
      .then((usuario) => admDefinirAvatarElemento("contaAvatar", usuario?.fotoUrl, admIniciais(nome)))
      .catch(() => {});
  }
}

let codigoAtual = "";

async function carregar() {
  try {
    // "Sou principal" agora é por estabelecimento (campo souDono, vindo da
    // API) — uma pessoa pode ser dona de um e só funcionária de outro. Isso
    // aqui é "sou dona de pelo menos um", que é o que já bastava para esta
    // página (gerenciar convites/pedidos é coisa de dono).
    const estabelecimentos = await admBuscarEstabelecimentos();
    const souPrincipalDeAlgo = estabelecimentos.some((e) => e.souDono);

    if (!souPrincipalDeAlgo) {
      document.getElementById("resumoSub").textContent = "Consulta rápida";
      document.getElementById("somenteVisualizacao").hidden = false;
      return;
    }

    const solicitacoes = await admBuscarSolicitacoes();

    document.getElementById("resumoSub").textContent =
      `${estabelecimentos.length} ${estabelecimentos.length === 1 ? "estabelecimento" : "estabelecimentos"}`;

    renderarCodigo(estabelecimentos);
    renderarSolicitacoes(solicitacoes);
    document.getElementById("conteudoEquipe").hidden = false;
  } catch (e) {
    const alvo = document.getElementById("erro");
    alvo.textContent = `Não foi possível carregar os dados (${e.message}).`;
    alvo.hidden = false;
    document.getElementById("resumoSub").textContent = "Sem conexão com a API";
  }
}

function renderarCodigo(estabelecimentos) {
  // Mostra o código do primeiro estabelecimento que essa pessoa realmente
  // possui (a lista agora também traz os de que ela só é funcionária, e
  // esses não têm código dela pra compartilhar).
  const principal = estabelecimentos.find((e) => e.souDono);
  codigoAtual = principal?.codigoAcesso || "";
  document.getElementById("codigoValor").textContent = codigoAtual || "—";
}

async function copiarCodigo() {
  if (!codigoAtual) return;
  try {
    await navigator.clipboard.writeText(codigoAtual);
    mostrarToast("Código copiado!");
  } catch (e) {
    mostrarToast("Não foi possível copiar.", true);
  }
}

function renderarSolicitacoes(lista) {
  atualizarContador(lista.length);

  const corpo = document.getElementById("corpoSolicitacoes");
  if (lista.length === 0) {
    corpo.innerHTML = `<tr><td colspan="5" class="tabela-vazia">Nenhuma solicitação pendente.</td></tr>`;
    return;
  }

  corpo.innerHTML = lista.map(s => `
    <tr data-id="${s.id}">
      <td>${admEscapar(s.nomeUsuario)}</td>
      <td class="equipe-usuario-email">${admEscapar(s.emailUsuario)}</td>
      <td>${admEscapar(s.nomeEstabelecimento)}</td>
      <td>${admFormatarData(s.dataSolicitacao)}</td>
      <td>
        <div class="equipe-acoes">
          <button type="button" class="btn-acao vermelho" onclick="responder(${s.id}, false)">Recusar</button>
          <button type="button" class="btn-acao verde" onclick="responder(${s.id}, true)">Aceitar</button>
        </div>
      </td>
    </tr>`).join("");
}

function atualizarContador(qtd) {
  document.getElementById("totalSolicitacoes").textContent = `${qtd} ${qtd === 1 ? "pendente" : "pendentes"}`;
}

async function responder(id, aceitar) {
  const linha = document.querySelector(`tr[data-id="${id}"]`);
  const botoes = linha ? Array.from(linha.querySelectorAll("button")) : [];
  botoes.forEach(b => (b.disabled = true));

  try {
    if (aceitar) {
      await admAceitarSolicitacao(id);
      mostrarToast("Solicitação aceita.");
    } else {
      await admRecusarSolicitacao(id);
      mostrarToast("Solicitação recusada.");
    }
    linha?.remove();

    const restantes = document.querySelectorAll("#corpoSolicitacoes tr[data-id]").length;
    atualizarContador(restantes);
    if (restantes === 0) {
      document.getElementById("corpoSolicitacoes").innerHTML =
        `<tr><td colspan="5" class="tabela-vazia">Nenhuma solicitação pendente.</td></tr>`;
    }
  } catch (e) {
    mostrarToast(e.message || "Não foi possível concluir.", true);
    botoes.forEach(b => (b.disabled = false));
  }
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
