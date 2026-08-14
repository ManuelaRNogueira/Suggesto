import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'detalhesSugestaoAdm.dart';

// Lista de sugestões do painel admin — versão mobile da tela equivalente do
// desktop (Suggesto_DesktopReact/renderer/src/pages/admin/Sugestoes.jsx).
// Ainda usa dados de exemplo, o app não está ligado à API.
class SugestoesAdm extends StatefulWidget {
  const SugestoesAdm({super.key});

  @override
  State<SugestoesAdm> createState() => _SugestoesAdmState();
}

class _SugestoesAdmState extends State<SugestoesAdm> {
  int paginaAtual = 1;
  String filtro = 'todos';
  String busca = '';

  final List<Map<String, dynamic>> sugestoes = [
    {
      'titulo': 'Melhorar a iluminação do pátio',
      'descricao':
          'A iluminação do pátio principal está muito fraca, principalmente durante o período noturno. '
              'Seria importante melhorar para garantir mais segurança e conforto para os alunos que ficam no período da noite.',
      'categoria': 'Estrutura',
      'status': 'pendente',
      'prioridade': 'alta',
      'tempo': 'há 2h',
      'autor': 'Manuela Nogueira',
      'data': '05/11/2024 | 14:30',
    },
    {
      'titulo': 'Adicionar mais opções vegetarianas',
      'descricao':
          'O cardápio do refeitório tem poucas opções sem carne. Ter mais alternativas vegetarianas ajudaria '
              'bastante quem segue esse tipo de dieta.',
      'categoria': 'Produtos e Serviços',
      'status': 'analise',
      'prioridade': 'media',
      'tempo': 'há 5h',
      'autor': 'Rafael Gonçalves',
      'data': '05/11/2024 | 09:10',
    },
    {
      'titulo': 'Melhorar atendimento da secretaria',
      'descricao':
          'O atendimento na secretaria costuma demorar bastante nos horários de pico. Um sistema de senhas '
              'ajudaria a organizar a fila.',
      'categoria': 'Atendimento',
      'status': 'implementado',
      'prioridade': 'media',
      'tempo': 'há 1d',
      'autor': 'Diogo Bernasconi',
      'data': '04/11/2024 | 11:45',
    },
    {
      'titulo': 'Criar mais espaços silenciosos para estudos',
      'descricao':
          'Falta um espaço reservado pra quem precisa estudar em silêncio antes das provas. A biblioteca já '
              'fica cheia rápido.',
      'categoria': 'Estrutura',
      'status': 'pendente',
      'prioridade': 'alta',
      'tempo': 'há 3h',
      'autor': 'Ana Paula',
      'data': '05/11/2024 | 08:20',
    },
    {
      'titulo': 'Ampliar horário da biblioteca',
      'descricao':
          'A biblioteca fecha muito cedo pra quem fica até mais tarde na escola. Ampliar o horário ajudaria '
              'bastante na época de provas.',
      'categoria': 'Organização',
      'status': 'recusado',
      'prioridade': 'baixa',
      'tempo': 'há 2d',
      'autor': 'Gui Meirelles',
      'data': '03/11/2024 | 16:00',
    },
    {
      'titulo': 'Instalar mais bebedouros nos corredores',
      'descricao':
          'Tem poucos bebedouros e nos horários de intervalo sempre forma fila. Instalar mais alguns nos '
              'corredores resolveria.',
      'categoria': 'Estrutura',
      'status': 'implementado',
      'prioridade': 'media',
      'tempo': 'há 3d',
      'autor': 'João Emerick',
      'data': '02/11/2024 | 10:05',
    },
    {
      'titulo': 'Melhorar a limpeza dos banheiros',
      'descricao':
          'Os banheiros do bloco B costumam ficar sem papel e sem sabonete no fim do dia. Seria bom reforçar '
              'a limpeza nesse horário.',
      'categoria': 'Higiene',
      'status': 'analise',
      'prioridade': 'alta',
      'tempo': 'há 3d',
      'autor': 'Carol Terazan',
      'data': '02/11/2024 | 07:40',
    },
  ];

  final List<_Filtro> filtros = const [
    _Filtro('Todos', 'todos'),
    _Filtro('Pendentes', 'pendente'),
    _Filtro('Em Análise', 'analise'),
    _Filtro('Implementados', 'implementado'),
  ];

  List<Map<String, dynamic>> get sugestoesFiltradas {
    return sugestoes.where((s) {
      if (filtro != 'todos' && s['status'] != filtro) return false;
      if (busca.isNotEmpty && !s['titulo'].toString().toLowerCase().contains(busca.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> sugestao) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesSugestaoAdm(sugestao: sugestao)),
    );
    // A tela de detalhes pode ter mudado o status (mesmo mapa, por referência) —
    // atualiza a lista pra refletir isso.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lista = sugestoesFiltradas;

    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sugestões',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'PoppinsBold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buscaCampo(),
                  const SizedBox(height: 14),
                  _filtrosChips(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma sugestão encontrada.',
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins'),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      itemCount: lista.length,
                      itemBuilder: (context, i) => _cartaoSugestao(lista[i]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  Widget _buscaCampo() {
    return Container(
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        onChanged: (v) => setState(() => busca = v),
        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Buscar sugestões',
          hintStyle: TextStyle(color: Colors.white38, fontFamily: 'Poppins', fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _filtrosChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filtros) ...[
            _chip(f),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(_Filtro f) {
    final ativo = filtro == f.chave;
    return GestureDetector(
      onTap: () => setState(() => filtro = f.chave),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? Cores.roxo : Cores.cartao,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? Cores.roxo : Cores.borda),
        ),
        child: Text(
          f.rotulo,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _cartaoSugestao(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () => _abrirDetalhes(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Cores.cartao,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Cores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                pillStatus(s['status']),
                Text(
                  s['tempo'],
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s['titulo'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categoria: ${s['categoria']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
                  ),
                ),
                if (s['prioridade'] == 'alta') _pillPrioridade(),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                s['autor'],
                style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraNavegacao() {
    final abas = [
      _Aba('Início', Icons.home_filled, '/inicioAdm'),
      _Aba('Sugestões', Icons.forum, '/sugestoesAdm'),
      _Aba('Estatísticas', Icons.bar_chart, null),
      _Aba('Perfil', Icons.person, null),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Cores.fundo,
        border: Border(top: BorderSide(color: Cores.cartao, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < abas.length; i++) _itemNavegacao(abas[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNavegacao(_Aba aba, int indice) {
    final ativo = paginaAtual == indice;
    return GestureDetector(
      onTap: () {
        setState(() => paginaAtual = indice);
        if (aba.rota == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${aba.rotulo} ainda não está pronto.',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          );
          return;
        }
        if (aba.rota != '/sugestoesAdm') Navigator.pushNamed(context, aba.rota!);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(aba.icone, color: ativo ? Colors.white : Colors.white54),
          const SizedBox(height: 4),
          Text(
            aba.rotulo,
            style: TextStyle(
              color: ativo ? Colors.white : Colors.white54,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

Widget _pillPrioridade() {
  return Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: const Color(0x29FF5252), borderRadius: BorderRadius.circular(6)),
    child: const Text(
      'Alta prioridade',
      style: TextStyle(color: Color(0xFFFF5252), fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}

class _Filtro {
  final String rotulo;
  final String chave;
  const _Filtro(this.rotulo, this.chave);
}

class _Aba {
  final String rotulo;
  final IconData icone;
  final String? rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
