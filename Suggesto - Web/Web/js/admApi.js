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

async function admFetchJson(url, opcoes = {}) {
  const resposta = await fetch(url, opcoes);
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

async function admBuscarSugestoes() {
  return admFetchJson(`${ADM_API_BASE}/admin/sugestoes${admQueryGerente()}`);
}

async function admBuscarUsuarios() {
  return admFetchJson(`${ADM_API_BASE}/admin/usuarios`);
}

async function admBuscarEstabelecimentos() {
  return admFetchJson(`${ADM_API_BASE}/admin/estabelecimentos${admQueryGerente()}`);
}

async function admAtualizarStatusSugestao(id, status) {
  return admFetchJson(`${ADM_API_BASE}/avaliacoes/${id}/status`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status }),
  });
}

async function admExcluirEstabelecimento(id) {
  const resposta = await fetch(`${ADM_API_BASE}/estabelecimentos/${id}`, { method: "DELETE" });
  if (!resposta.ok) throw new Error(`Erro ${resposta.status}`);
}

async function admBloquearUsuario(id) {
  return admFetchJson(`${ADM_API_BASE}/admin/usuarios/${id}/bloquear`, { method: "PUT" });
}

function admIniciais(nome) {
  if (!nome) return "—";
  return nome.trim().split(/\s+/).slice(0, 2).map(p => p[0]?.toUpperCase() || "").join("");
}

function admFormatarData(iso) {
  if (!iso) return "—";
  const data = new Date(iso);
  if (Number.isNaN(data.getTime())) return "—";
  const diff = Date.now() - data.getTime();
  const horas = Math.floor(diff / 3600000);
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

function admMostrarToast(msg, tipo = "ok") {
  let toast = document.getElementById("admToast");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "admToast";
    toast.className = "toast";
    document.body.appendChild(toast);
  }
  toast.textContent = msg;
  toast.classList.toggle("toast-erro", tipo === "erro");
  toast.classList.add("visivel");
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => toast.classList.remove("visivel"), 3200);
}
