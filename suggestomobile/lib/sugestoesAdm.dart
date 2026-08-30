import 'package:flutter/material.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'sessao.dart';
import 'api.dart';
import 'detalhesSugestaoAdm.dart';
import 'cartaoSugestaoAdm.dart';

// Lista de sugestões do painel admin — versão mobile da tela equivalente do
// desktop (Suggesto_DesktopReact/renderer/src/pages/admin/Sugestoes.jsx).
// Busca em GET /api/admin/sugestoes.
class SugestoesAdm extends StatefulWidget {
  const SugestoesAdm({super.key});

  @override
  State<SugestoesAdm> createState() => _SugestoesAdmState();
}

class _SugestoesAdmState extends State<SugestoesAdm> {
  int paginaAtual = 1;
  String filtro = 'todos';
  int? estabelecimentoFiltroId;
  String busca = '';

  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> sugestoes = [];
  // Estabelecimentos reais vinculados a este administrador (GET
  // /api/admin/estabelecimentos) — usados como opções do filtro.
  List<Map<String, dynamic>> estabelecimentosAdmin = [];

  final List<_Filtro> filtros = const [
    _Filtro('Todos', 'todos'),
    _Filtro('Pendentes', 'pendente'),
    _Filtro('Implementadas', 'implementado'),
    _Filtro('Recusadas', 'recusado'),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final resultados = await Future.wait([
        buscarSugestoesAdmin(idGerente: Sessao.idUsuario),
        buscarEstabelecimentosAdmin(idGerente: Sessao.idUsuario),
      ]);
      setState(() {
        sugestoes = resultados[0].cast<Map<String, dynamic>>();
        estabelecimentosAdmin = resultados[1].cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  List<Map<String, dynamic>> get sugestoesFiltradas {
    return sugestoes.where((s) {
      if (filtro != 'todos' && s['statusUi'] != filtro) return false;
      if (estabelecimentoFiltroId != null &&
          (s['estabelecimentoId'] as num?)?.toInt() !=
              estabelecimentoFiltroId) {
        return false;
      }
      if (busca.isNotEmpty) {
        final titulo = tituloSugestao(s['comentario'] as String?).toLowerCase();
        if (!titulo.contains(busca.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> sugestao) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesSugestaoAdm(sugestao: sugestao),
      ),
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
                  if (estabelecimentosAdmin.length > 1) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _seletorEstabelecimento(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _filtrosChips(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _corpo(lista)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  Widget _corpo(List<Map<String, dynamic>> lista) {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: Cores.roxo));
    }
    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _carregar,
                child: const Text(
                  'Tentar de novo',
                  style: TextStyle(color: Cores.roxo, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma sugestão encontrada.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: Cores.roxo,
      onRefresh: _carregar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: lista.length,
        itemBuilder: (context, i) => cartaoSugestaoAdm(
          sugestao: lista[i],
          onTap: () => _abrirDetalhes(lista[i]),
        ),
      ),
    );
  }

  Widget _buscaCampo() {
    return Container(
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (v) => setState(() => busca = v),
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          hintText: 'Buscar sugestões',
          hintStyle: TextStyle(
            color: Colors.white38,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
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
          for (final f in filtros) ...[_chip(f), const SizedBox(width: 8)],
        ],
      ),
    );
  }

  Widget _chip(_Filtro f) {
    return _chipBase(
      rotulo: f.rotulo,
      ativo: filtro == f.chave,
      onTap: () => setState(() => filtro = f.chave),
    );
  }

  String get _nomeEstabelecimentoFiltro {
    if (estabelecimentoFiltroId == null) return 'Todos os estabelecimentos';
    final encontrado = estabelecimentosAdmin.firstWhere(
      (e) => (e['id'] as num).toInt() == estabelecimentoFiltroId,
      orElse: () => const {},
    );
    return (encontrado['nome'] as String?) ?? 'Estabelecimento';
  }

  // Seletor compacto de estabelecimento — só aparece quando o admin tem mais
  // de um (com um só, não há o que filtrar). Mostra direto qual está
  // selecionado, sem precisar abrir o painel pra saber.
  Widget _seletorEstabelecimento() {
    final ativo = estabelecimentoFiltroId != null;
    return GestureDetector(
      onTap: _abrirSeletorEstabelecimento,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ativo ? Cores.roxo.withOpacity(0.15) : Cores.cartao,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ativo ? Cores.roxo : Cores.borda),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 16,
              color: ativo ? Cores.roxo : Colors.white54,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _nomeEstabelecimentoFiltro,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ativo ? Cores.roxo : Colors.white70,
                  fontSize: 13,
                  fontFamily: 'PoppinsSemi',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: ativo ? Cores.roxo : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet de seleção — mesmo modelo já usado nos outros filtros do
  // app (fundo Cores.cartao, topo arredondado, alça de arraste). Lista em
  // vez de chips: nomes de estabelecimento podem ser longos, e uma lista
  // com a opção marcada fica mais clara que vários botões lado a lado.
  void _abrirSeletorEstabelecimento() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          void selecionar(int? id) {
            setModalState(() => setState(() => estabelecimentoFiltroId = id));
            Navigator.pop(context);
          }

          return Container(
            decoration: const BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Selecionar estabelecimento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PoppinsBold',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _linhaEstabelecimento(
                    nome: 'Todos os estabelecimentos',
                    ativo: estabelecimentoFiltroId == null,
                    onTap: () => selecionar(null),
                  ),
                  for (final e in estabelecimentosAdmin)
                    _linhaEstabelecimento(
                      nome: (e['nome'] as String?) ?? 'Estabelecimento',
                      ativo:
                          estabelecimentoFiltroId == (e['id'] as num).toInt(),
                      onTap: () => selecionar((e['id'] as num).toInt()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _linhaEstabelecimento({
    required String nome,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ativo ? Cores.roxo.withOpacity(0.15) : const Color(0xFF2A1A4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? Cores.roxo : const Color(0xFF3A2A5A),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 16,
              color: ativo ? Cores.roxo : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nome,
                style: TextStyle(
                  color: ativo ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (ativo)
              const Icon(Icons.check_circle, size: 18, color: Cores.roxo),
          ],
        ),
      ),
    );
  }

  Widget _chipBase({
    required String rotulo,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? Cores.roxo : Cores.cartao,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? Cores.roxo : Cores.borda),
        ),
        child: Text(
          rotulo,
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

  Widget _buildBarraNavegacao() {
    final abas = [
      _Aba('Início', Icons.home_filled, '/inicioAdm'),
      _Aba('Sugestões', Icons.forum, '/sugestoesAdm'),
      _Aba('Perfil', Icons.person, '/perfilAdm'),
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
        if (aba.rota != '/sugestoesAdm')
          Navigator.pushNamed(context, aba.rota!);
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
