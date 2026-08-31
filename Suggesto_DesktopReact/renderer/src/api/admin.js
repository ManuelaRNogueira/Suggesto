// Camada de acesso à API do painel administrativo (a versão desktop/Electron
// do que já existe no site, em "js/admApi.js"). É por aqui que o painel
// descobre quais estabelecimentos a pessoa administra, confere plano e
// permissão antes de liberar uma ação, e conversa com o resto do back-end
// (sugestões, usuários, equipe, planos...).

// Por padrão aponta para o backend hospedado no Render. Para rodar contra o
// backend local, defina VITE_API_BASE=http://localhost:8080/api antes do build/dev.
export const API_BASE = import.meta.env.VITE_API_BASE || "https://suggesto-api.onrender.com/api";

// Monta a URL da foto pra exibir na tela. Ela pode chegar de duas formas: já
// como um link pronto (quando foi parar no Cloudinary) ou só o nome cru do
// arquivo (quando caiu no fallback de guardar no disco do próprio servidor)
// — essa função reconhece os dois casos e devolve sempre algo exibível.
export function urlFoto(fotoPath) {
  const nome = fotoPath ? String(fotoPath).trim() : "";
  if (!nome) return null;
  if (/^https?:\/\//i.test(nome)) return nome;
  const limpo = nome.replace(/^\/?uploads\//, "");
  return `${API_BASE.replace("/api", "")}/uploads/${limpo}`;
}

// Hoje em dia uma pessoa pode ser dona de um estabelecimento e, ao mesmo
// tempo, funcionária de outro — não dá mais pra falar em "o dono da sessão"
// como se fosse uma coisa só. Quem resolve isso é o próprio back-end: a
// partir do idUsuario, ele monta o portfólio inteiro (o que a pessoa
// possui + onde ela trabalha). Por isso é sempre o idUsuario que mandamos
// como "idGerente" nas chamadas abaixo.
export function idGerente() {
  return localStorage.getItem("idUsuario");
}

// "Ser dona" não é mais um flag único de sessão, é uma propriedade de CADA
// estabelecimento (o campo souDono que vem em buscarEstabelecimentos /
// buscarMinhasEstabelecimentos). Essa função só responde uma pergunta mais
// simples — "essa pessoa é dona de PELO MENOS um lugar?" — usada pra
// decidir se mostra telas como Plano e Solicitações no menu.
export async function possuoAlgumEstabelecimento() {
  const estabs = await buscarEstabelecimentos();
  return (estabs || []).some((e) => e.souDono);
}

// Monta a query string colando o idGerente automaticamente (pra não
// esquecer em nenhuma chamada) e, se vierem, os parâmetros extras — filtra
// undefined/null pra não mandar "idEstabelecimento=undefined" pro servidor.
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

// A "telefonista" central deste arquivo: toda função abaixo que fala com o
// servidor passa por aqui. Faz o fetch, confere se deu certo e, se não deu,
// já lança um erro com a mensagem certa — assim cada função de API não
// precisa repetir esse try/catch inteiro.
async function fetchJson(url, opcoes = {}) {
  const resposta = await fetch(url, opcoes);
  if (!resposta.ok) {
    const erro = await resposta.text().catch(() => "");
    throw new Error(erro || `Erro ${resposta.status}`);
  }
  if (resposta.status === 204) return null;
  return resposta.json();
}

// Números gerais e listas que alimentam as telas do painel: métricas
// (gráficos/estatísticas), sugestões recebidas, usuários e os
// estabelecimentos do gerente logado — todas já filtradas pelo idGerente
// (ver queryGerente acima).
export function buscarMetricas(meses, idEstabelecimento) {
  return fetchJson(`${API_BASE}/admin/metricas${queryGerente({ meses, idEstabelecimento })}`);
}

export function buscarSugestoes() {
  return fetchJson(`${API_BASE}/admin/sugestoes${queryGerente()}`);
}

export function buscarUsuarios() {
  return fetchJson(`${API_BASE}/admin/usuarios${queryGerente()}`);
}

export function buscarEstabelecimentos() {
  return fetchJson(`${API_BASE}/admin/estabelecimentos${queryGerente()}`);
}

// Portfólio completo de quem está logado: os estabelecimentos que possui +
// os de que é funcionária, tudo junto sem distinção — diferente de
// "estabelecimentos que eu possuo" (usado em Solicitações, que é só-dono
// de propósito, porque só o dono pode aprovar pedido de entrada na equipe).
export function buscarMinhasEstabelecimentos() {
  const idUsuario = localStorage.getItem("idUsuario");
  return fetchJson(`${API_BASE}/estabelecimentos/minhas/${idUsuario}`);
}

// Desativa (não apaga) um estabelecimento. O back-end confere pelo
// idSolicitante se quem está pedindo realmente pode fazer isso.
export function desativarEstabelecimento(id) {
  const idSolicitante = localStorage.getItem("idUsuario");
  return fetchJson(
    `${API_BASE}/estabelecimentos/${id}?idSolicitante=${encodeURIComponent(idSolicitante)}`,
    { method: "DELETE" },
  );
}

export function buscarUsuario(id) {
  return fetchJson(`${API_BASE}/usuarios/${id}`);
}

// Remover alguém da equipe é uma ação séria, então tem duas travas: só o
// administrador principal do estabelecimento pode fazer isso, e só
// funciona se ele também digitar o código de acesso do local como
// confirmação — a mesma regra usada pra editar o estabelecimento (ver
// ModalEditarEstabelecimento.jsx). Por isso essa função não usa o
// fetchJson genérico: precisa ler o corpo da resposta mesmo quando dá erro,
// pra mostrar a mensagem exata que o servidor mandou (ex: "código errado").
export async function removerAdministrador(idEstabelecimento, idUsuario, codigoConfirmacao) {
  const idSolicitante = localStorage.getItem("idUsuario");
  const url =
    `${API_BASE}/estabelecimentos/${idEstabelecimento}/administradores/${idUsuario}` +
    `?idSolicitante=${idSolicitante}&codigoConfirmacao=${encodeURIComponent((codigoConfirmacao || "").trim())}`;
  const resposta = await fetch(url, { method: "DELETE" });
  const dados = await resposta.json().catch(() => null);
  if (!resposta.ok) {
    throw new Error(dados?.message || `Erro ${resposta.status}`);
  }
  return dados;
}

// ── Planos ────────────────────────────────────────────────────────────────
// Limites do plano do admin logado (quantos estabelecimentos, quanta
// equipe etc. ele pode ter) — usado pra esconder na tela o que o plano
// atual não inclui.
export function buscarMeuPlano() {
  const id = localStorage.getItem("idUsuario");
  return fetchJson(`${API_BASE}/planos/meu?idUsuario=${id}`);
}

// Catálogo completo (Básico/Pro/Empresarial), pra tela de troca de plano.
export function listarPlanos() {
  return fetchJson(`${API_BASE}/planos`);
}

// Trocar de plano também é coisa só de dono principal — o app nem deveria
// deixar chegar até aqui se não for, mas o back-end confere de novo do
// lado dele e recusa a troca se o que a pessoa já tem hoje (mais
// estabelecimentos, mais gente na equipe...) não couber no plano novo.
export function trocarPlano(nomePlano) {
  const id = localStorage.getItem("idUsuario");
  return fetchJson(`${API_BASE}/planos/meu`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idUsuario: id, plano: nomePlano }),
  });
}

// ── Pedidos de entrada na equipe ────────────────────────────────────────
// Quando alguém usa o código de acesso de um estabelecimento pra pedir
// entrada (ver mobile), o pedido fica pendente até o dono principal
// aceitar ou recusar por aqui — buscarSolicitacoes lista o que está
// esperando resposta.
export function buscarSolicitacoes() {
  return fetchJson(`${API_BASE}/estabelecimentos/solicitacoes${queryGerente()}`);
}

export function aceitarSolicitacao(id) {
  return fetchJson(`${API_BASE}/estabelecimentos/solicitacoes/${id}/aceitar`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idGerente: idGerente() }),
  });
}

export function recusarSolicitacao(id) {
  return fetchJson(`${API_BASE}/estabelecimentos/solicitacoes/${id}/recusar`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idGerente: idGerente() }),
  });
}

// ── Sugestões ────────────────────────────────────────────────────────────
// Muda o status de uma sugestão recebida, ou grava a resposta que o admin
// escreveu pra ela.
export function atualizarStatusSugestao(id, status) {
  return fetchJson(`${API_BASE}/avaliacoes/${id}/status`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status }),
  });
}

export function responderSugestao(id, { idAdmin, resposta }) {
  return fetchJson(`${API_BASE}/avaliacoes/${id}/resposta`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idAdmin, resposta }),
  });
}

// O endpoint espera multipart/form-data (por isso o FormData em vez de
// JSON), mas essa função só manda os campos de texto — o painel desktop
// não tem tela de trocar a foto do usuário por aqui, só nome/telefone/cidade.
export function atualizarPerfil(id, { nome, telefone, cidade }) {
  const corpo = new FormData();
  if (nome !== undefined) corpo.append("nome", nome);
  if (telefone !== undefined) corpo.append("telefone", telefone);
  if (cidade !== undefined) corpo.append("cidade", cidade);
  return fetchJson(`${API_BASE}/usuarios/${id}`, { method: "PUT", body: corpo });
}

// ── Formatação ────────────────────────────────────────────────────────────
// Daqui pra baixo não é mais sobre falar com o servidor — são só ajudantes
// pra deixar o que vem da API bonito na tela (iniciais pro avatar, data
// relativa tipo "há 2h", nome do status, título da sugestão).

// Pega até duas iniciais do nome pra usar como avatar quando não tem foto
// (ex: "Maria Silva" → "MS").
export function iniciais(nome) {
  if (!nome) return "—";
  return nome
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() || "")
    .join("");
}

// Transforma uma data ISO em algo mais fácil de ler de relance: "agora",
// "há 3h", "há 2d", e só cai pra data cheia (dd/mm/aaaa) depois de uma semana.
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

// Os três status possíveis de uma sugestão, com o rótulo em português pra
// mostrar na tela e o valor cru que a API espera receber.
export const STATUS = [
  { id: "pendente", label: "Pendente", envia: "pendente" },
  { id: "implementado", label: "Implementado", envia: "implementado" },
  { id: "recusado", label: "Recusado", envia: "recusado" },
];

export function labelStatus(statusUi) {
  return STATUS.find((s) => s.id === statusUi)?.label || "Pendente";
}

// A sugestão não tem campo de título no banco — só comentário. Aqui a
// gente "inventa" um título pegando o começo do comentário (até 90
// caracteres, com "…" se cortar no meio), só pra tela ter algo curto pra
// mostrar antes de abrir o texto completo.
export function tituloSugestao(comentario) {
  if (!comentario || !comentario.trim()) return "Sugestão sem descrição";
  const limpo = comentario.trim().replace(/\s+/g, " ");
  return limpo.length > 90 ? `${limpo.slice(0, 90)}…` : limpo;
}
