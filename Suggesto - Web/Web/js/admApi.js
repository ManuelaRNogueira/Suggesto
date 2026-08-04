// Acesso à API administrativa usado pelo resumo web (somente leitura).
// A gestão completa — triagem, estatísticas, equipe — vive no app desktop.

const ADM_API_BASE = "http://localhost:8080/api";

function admIdGerente() {
  return localStorage.getItem("idUsuario");
}

function admVerificarSessao() {
  if (localStorage.getItem("tipoUsuario") !== "Administrador") {
    window.location.href = "login.html";
    return false;
  }
  return true;
}

async function admFetchJson(url) {
  const resposta = await fetch(url);
  if (!resposta.ok) {
    const erro = await resposta.text().catch(() => "");
    throw new Error(erro || `Erro ${resposta.status}`);
  }
  if (resposta.status === 204) return null;
  return resposta.json();
}

function admQueryGerente() {
  const id = admIdGerente();
  return id ? `?idGerente=${id}` : "";
}

async function admBuscarMetricas() {
  return admFetchJson(`${ADM_API_BASE}/admin/metricas${admQueryGerente()}`);
}

async function admBuscarEstabelecimentos() {
  return admFetchJson(`${ADM_API_BASE}/admin/estabelecimentos${admQueryGerente()}`);
}

async function admBuscarUsuario(id) {
  return admFetchJson(`${ADM_API_BASE}/usuarios/${id}`);
}

function admIniciais(nome) {
  if (!nome) return "—";
  return nome.trim().split(/\s+/).slice(0, 2).map(p => p[0]?.toUpperCase() || "").join("");
}

function admFormatarData(iso) {
  if (!iso) return "—";
  const data = new Date(iso);
  if (Number.isNaN(data.getTime())) return "—";
  const horas = Math.floor((Date.now() - data.getTime()) / 3600000);
  if (horas < 1) return "agora";
  if (horas < 24) return `há ${horas}h`;
  const dias = Math.floor(horas / 24);
  if (dias < 7) return `há ${dias}d`;
  return data.toLocaleDateString("pt-BR");
}

function admLabelStatus(statusUi) {
  const mapa = {
    pendente: "Pendente",
    analise: "Em análise",
    implementado: "Implementado",
    recusado: "Recusado",
  };
  return mapa[statusUi] || "Pendente";
}

// Sugestão não tem campo de título no banco — só comentário.
function admTituloSugestao(comentario) {
  if (!comentario || !comentario.trim()) return "Sugestão sem descrição";
  const limpo = comentario.trim().replace(/\s+/g, " ");
  return limpo.length > 90 ? `${limpo.slice(0, 90)}…` : limpo;
}

function admEscapar(texto) {
  const div = document.createElement("div");
  div.textContent = texto ?? "";
  return div.innerHTML;
}
