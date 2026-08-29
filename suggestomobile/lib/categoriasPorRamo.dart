// Config central: define quais categorias de sugestão aparecem pra cada ramo
// de estabelecimento (sugerir.dart). A chave precisa bater exatamente com o
// valor salvo em estabelecimento.categoria. Mesmo conteúdo do
// "Suggesto - Web/Web/js/categoriasPorRamo.js" — mantenha os dois em sincronia.
//
// Pra adicionar um ramo novo ou mudar as categorias de um já existente, só
// mexer aqui — nada mais na tela precisa mudar. Se o nome de uma categoria
// daqui não existir na tabela `categoria` do banco, ela simplesmente não
// aparece (ver filtrarCategoriasPorRamo) — categorias novas entram via
// apiLogin/scripts/adicionar_categorias_por_ramo.sql.
const Map<String, List<String>> categoriasPorRamo = {
  'Restaurante': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Ambiente'],
  'Bar': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Ambiente'],
  'Pizzaria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Ambiente'],
  'Cafeteria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Ambiente'],
  'Hamburgueria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Ambiente'],

  'Lanchonete': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Agilidade'],
  'Food Truck': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Agilidade'],

  'Padaria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Variedade'],
  'Sorveteria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Variedade'],
  'Doceria / Confeitaria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Variedade'],
  'Açaiteria': ['Atendimento', 'Cardápio', 'Qualidade da comida', 'Higiene', 'Preço', 'Variedade'],

  'Academia': ['Atendimento', 'Equipamentos', 'Estrutura', 'Limpeza', 'Horários', 'Aulas'],

  'Hotel / Pousada': ['Atendimento', 'Quartos', 'Limpeza', 'Café da manhã', 'Estrutura', 'Serviços'],

  'Escola / Educação': ['Atendimento', 'Ensino', 'Estrutura', 'Organização', 'Limpeza', 'Recursos'],

  'Salão de Beleza / Barbearia': ['Atendimento', 'Qualidade do serviço', 'Higiene', 'Preço', 'Ambiente', 'Agilidade'],
  'Clínica / Consultório de Saúde': ['Atendimento', 'Qualidade do serviço', 'Higiene', 'Estrutura', 'Preço', 'Agilidade'],

  'Farmácia': ['Atendimento', 'Preço', 'Variedade', 'Organização', 'Higiene', 'Agilidade'],
  'Petshop': ['Atendimento', 'Preço', 'Variedade', 'Higiene', 'Cuidado com os animais', 'Estrutura'],
  'Loja / Comércio': ['Atendimento', 'Preço', 'Variedade', 'Qualidade do produto', 'Organização', 'Ambiente'],
  'Supermercado / Mercado': ['Atendimento', 'Preço', 'Variedade', 'Organização', 'Higiene', 'Agilidade'],

  'Oficina Automotiva': ['Atendimento', 'Preço', 'Qualidade do serviço', 'Prazo de entrega', 'Organização', 'Transparência'],
  'Posto de Combustível': ['Atendimento', 'Preço', 'Limpeza', 'Agilidade', 'Estrutura', 'Segurança'],

  'Escritório / Empresa (Tecnologia e Serviços)': ['Atendimento', 'Qualidade do produto', 'Preço', 'Suporte', 'Prazo de entrega', 'Organização'],
  'Coworking': ['Atendimento', 'Estrutura', 'Limpeza', 'Internet/Wi-Fi', 'Preço', 'Ambiente'],
  'Espaço para Eventos': ['Atendimento', 'Estrutura', 'Limpeza', 'Organização', 'Preço', 'Equipamentos'],
  'Banco / Serviços Financeiros': ['Atendimento', 'Agilidade', 'Preço', 'Organização', 'Suporte', 'Segurança'],

  // Apresentação do Suggesto (feira/demo) — não é um espaço físico comercial,
  // então avalia o app em si (design, uso, funcionalidades...), não
  // atendimento/estrutura. Lista fechada, só estas 8.
  'Apresentação': [
    'Design e interface',
    'Facilidade de uso',
    'Funcionalidades',
    'Desempenho',
    'Experiência do usuário',
    'Acessibilidade',
    'Proposta do projeto',
    'Outro',
  ],
  'Evento': ['Atendimento', 'Organização', 'Estrutura', 'Ambiente', 'Preço', 'Outro'],
};

// Usado pro ramo "Outro" e pra qualquer ramo ainda não configurado acima.
const List<String> categoriasPadrao = ['Atendimento', 'Qualidade do produto', 'Preço', 'Estrutura', 'Ambiente', 'Outro'];

// Recebe a lista completa de categorias vinda de buscarCategorias() e o ramo
// do estabelecimento (local['categoria']), e devolve só as categorias certas
// pra esse ramo, na ordem definida acima.
List<Map<String, dynamic>> filtrarCategoriasPorRamo(
  List<Map<String, dynamic>> disponiveis,
  String? ramo,
) {
  final nomes = categoriasPorRamo[ramo] ?? categoriasPadrao;
  final porNome = <String, Map<String, dynamic>>{
    for (final c in disponiveis) (c['nomeCategoria'] as String? ?? ''): c,
  };
  return nomes.where(porNome.containsKey).map((nome) => porNome[nome]!).toList();
}
