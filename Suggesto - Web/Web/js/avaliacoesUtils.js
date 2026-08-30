// Lista única de tipos de estabelecimento, usada no cadastro pela equipe
// (ModalEstabelecimento.jsx) e no autocadastro pelo site (cadastroAdm.html) —
// mantenha as três em sincronia.
const CATEGORIAS_OFICIAIS = [
  { slug: "restaurante", label: "Restaurante" },
  { slug: "bar", label: "Bar" },
  { slug: "lanchonete", label: "Lanchonete" },
  { slug: "pizzaria", label: "Pizzaria" },
  { slug: "cafeteria", label: "Cafeteria" },
  { slug: "padaria", label: "Padaria" },
  { slug: "sorveteria", label: "Sorveteria" },
  { slug: "hamburgueria", label: "Hamburgueria" },
  { slug: "doceria", label: "Doceria / Confeitaria" },
  { slug: "acaiteria", label: "Açaiteria" },
  { slug: "food-truck", label: "Food Truck" },
  { slug: "hotel-pousada", label: "Hotel / Pousada" },
  { slug: "academia", label: "Academia" },
  { slug: "salao-beleza", label: "Salão de Beleza / Barbearia" },
  { slug: "clinica-saude", label: "Clínica / Consultório de Saúde" },
  { slug: "farmacia", label: "Farmácia" },
  { slug: "escola-educacao", label: "Escola / Educação" },
  { slug: "petshop", label: "Petshop" },
  { slug: "loja-comercio", label: "Loja / Comércio" },
  { slug: "supermercado", label: "Supermercado / Mercado" },
  { slug: "oficina", label: "Oficina Automotiva" },
  { slug: "posto-combustivel", label: "Posto de Combustível" },
  { slug: "escritorio-empresa", label: "Escritório / Empresa (Tecnologia e Serviços)" },
  { slug: "coworking", label: "Coworking" },
  { slug: "espaco-eventos", label: "Espaço para Eventos" },
  { slug: "banco", label: "Banco / Serviços Financeiros" },
  { slug: "outro", label: "Outro" },
];

// Tipo do feedback (o que o cliente escolhe no passo 1 de fazerSugestao.html).
// Não confundir com a categoria da avaliação, que é a área (Atendimento, Higiene...).
const TIPOS_FEEDBACK = [
  { slug: "sugestao", label: "Sugestão" },
  { slug: "critica", label: "Crítica" },
  { slug: "elogio", label: "Elogio" },
];

function normalizarTexto(valor) {
  return (valor || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/_/g, " ")
    .trim();
}

function chaveStatus(status) {
  const s = normalizarTexto(status).replace(/\s+/g, "");
  if (
    ["aceita", "aceito", "aprovada", "aprovado", "resolvida", "resolvido", "implementado", "implementada"].includes(s)
  ) {
    return "aceita";
  }
  if (["recusada", "recusado"].includes(s)) return "recusada";
  return "pendente";
}

function isStatusAprovado(status) {
  return chaveStatus(status) === "aceita";
}

function rotuloStatus(status) {
  const chave = chaveStatus(status);
  if (chave === "aceita") return "Aprovada";
  if (chave === "recusada") return "Recusada";
  return "Pendente";
}

function iconeStatus(status) {
  const chave = chaveStatus(status);
  if (chave === "aceita") return "fa-check-circle";
  if (chave === "recusada") return "fa-times-circle";
  return "fa-clock";
}

function slugCategoriaEstabelecimento(categoria) {
  const texto = normalizarTexto(categoria);
  const encontrada = CATEGORIAS_OFICIAIS.find(
    (cat) => texto === normalizarTexto(cat.label)
  );
  return encontrada ? encontrada.slug : "outro";
}

// Gera um chip por categoria oficial dentro do container informado, depois
// do "Todos"/"Todas as categorias" que já vem fixo no HTML. Usado por
// inicioCli.js, locaisSalvosCli.js e sugestoesCli.js — assim as três nunca
// ficam com uma lista de categorias desatualizada em relação à oficial.
function gerarChipsCategoria(containerId, classeChip) {
  const container = document.getElementById(containerId);
  if (!container) return;

  CATEGORIAS_OFICIAIS.forEach((cat) => {
    const botao = document.createElement("button");
    botao.type = "button";
    botao.className = classeChip;
    botao.textContent = cat.label;
    botao.onclick = () => filtrarCategoria(botao, cat.slug);
    container.appendChild(botao);
  });
}

function rotuloCategoriaAvaliacao(sugestao) {
  if (sugestao?.categoria?.nomeCategoria) return sugestao.categoria.nomeCategoria;
  return "Geral";
}

function chaveTipo(tipo) {
  const texto = normalizarTexto(tipo).replace(/\s+/g, "");
  const encontrado = TIPOS_FEEDBACK.find((t) => texto === t.slug);
  return encontrado ? encontrado.slug : "sugestao";
}

function rotuloTipo(tipo) {
  const chave = chaveTipo(tipo);
  return TIPOS_FEEDBACK.find((t) => t.slug === chave).label;
}

function classeTagCategoria(nomeCategoria) {
  return `tag-${normalizarTexto(nomeCategoria).replace(/\s+/g, "-")}`;
}
