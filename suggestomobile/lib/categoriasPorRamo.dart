//categorias de sugestão que aparecem pra cada ramo de estabelecimento
//o nome do ramo tem que ser igual ao salvo no banco
//manter igual ao categoriasPorRamo.js do site
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

  //apresentação do Suggesto (feira): avalia o app e a equipe
  'Apresentação': [
    'Design e interface',
    'Facilidade de uso',
    'Funcionalidades',
    'Desempenho',
    'Experiência do usuário',
    'Acessibilidade',
    'Proposta do projeto',
    'Clareza da apresentação',
    'Organização da apresentação',
    'Comunicação da equipe',
    'Demonstração do sistema',
    'Outro',
  ],
  'Evento': ['Atendimento', 'Organização', 'Estrutura', 'Ambiente', 'Preço', 'Outro'],
};

//categorias pra ramos que não estão na lista acima
const List<String> categoriasPadrao = ['Atendimento', 'Qualidade do produto', 'Preço', 'Estrutura', 'Ambiente', 'Outro'];

//filtro: das categorias que vieram do servidor, deixa só as do ramo
//(na ordem da lista acima)
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
