const CATEGORIAS_OFICIAIS = [
  { slug: "restaurante", label: "Restaurante" },
  { slug: "bar", label: "Bar" },
  { slug: "lanchonete", label: "Lanchonete" },
  { slug: "pizzaria", label: "Pizzaria" },
  { slug: "cafeteria", label: "Cafeteria" },
  { slug: "padaria", label: "Padaria" },
  { slug: "sorveteria", label: "Sorveteria" },
  { slug: "outro", label: "Outro" },
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
    (cat) => texto === cat.slug || texto.startsWith(cat.slug)
  );
  return encontrada ? encontrada.slug : "outro";
}

function rotuloCategoriaAvaliacao(sugestao) {
  if (sugestao?.categoria?.nomeCategoria) return sugestao.categoria.nomeCategoria;
  return "Geral";
}

function classeTagCategoria(nomeCategoria) {
  return `tag-${normalizarTexto(nomeCategoria).replace(/\s+/g, "-")}`;
}
