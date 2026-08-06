// Camada de acesso à API administrativa.
// Porte do js/admApi.js do projeto web para o desktop.

export const API_BASE = "http://localhost:8080/api";

export function idGerente() {
  return localStorage.getItem("idGerenteEfetivo") || localStorage.getItem("idUsuario");
}

function queryGerente(extra = {}) {
  const params = new URLSearchParams();
  const id = idGerente();
  if (id) params.set("idGerente", id);
  Object.entries(extra).forEach(([chave, valor]) => {
    if (valor !== undefined && valor !== null) params.set(chave, valor);
  });
  const texto = params.toString();
  return texto ? `?${texto}` : "";
}

async function fetchJson(url, opcoes = {}) {
  const resposta = await fetch(url, opcoes);
  if (!resposta.ok) {
    const erro = await resposta.text().catch(() => "");
    throw new Error(erro || `Erro ${resposta.status}`);
  }
  if (resposta.status === 204) return null;
  return resposta.json();
}

export function buscarMetricas(meses) {
  return fetchJson(`${API_BASE}/admin/metricas${queryGerente({ meses })}`);
}

export function buscarSugestoes() {
  return fetchJson(`${API_BASE}/admin/sugestoes${queryGerente()}`);
}

export function buscarUsuarios() {
  return fetchJson(`${API_BASE}/admin/usuarios`);
}

export function buscarEstabelecimentos() {
  return fetchJson(`${API_BASE}/admin/estabelecimentos${queryGerente()}`);
}

export function buscarUsuario(id) {
  return fetchJson(`${API_BASE}/usuarios/${id}`);
}

export function atualizarStatusSugestao(id, status) {
  return fetchJson(`${API_BASE}/avaliacoes/${id}/status`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status }),
  });
}

// PUT /api/usuarios/{id} aceita apenas nome, telefone, cidade e foto.
export function atualizarPerfil(id, { nome, telefone, cidade }) {
  const corpo = new FormData();
  if (nome !== undefined) corpo.append("nome", nome);
  if (telefone !== undefined) corpo.append("telefone", telefone);
  if (cidade !== undefined) corpo.append("cidade", cidade);
  return fetchJson(`${API_BASE}/usuarios/${id}`, { method: "PUT", body: corpo });
}

// ── Formatação ────────────────────────────────────────────────────────────

export function iniciais(nome) {
  if (!nome) return "—";
  return nome
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() || "")
    .join("");
}

export function formatarData(iso) {
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

export const STATUS = [
  { id: "pendente", label: "Pendente", envia: "pendente" },
  { id: "analise", label: "Em análise", envia: "analise" },
  { id: "implementado", label: "Implementado", envia: "implementado" },
  { id: "recusado", label: "Recusado", envia: "recusado" },
];

export function labelStatus(statusUi) {
  return STATUS.find((s) => s.id === statusUi)?.label || "Pendente";
}

// A sugestão não tem campo de título no banco — só comentário.
// Usamos a primeira frase como título e guardamos o resto como detalhe.
export function tituloSugestao(comentario) {
  if (!comentario || !comentario.trim()) return "Sugestão sem descrição";
  const limpo = comentario.trim().replace(/\s+/g, " ");
  return limpo.length > 90 ? `${limpo.slice(0, 90)}…` : limpo;
}
