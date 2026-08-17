import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'formatacao.dart';
import 'sessao.dart';
import 'api.dart';
import 'detalhesSugestaoAdm.dart';

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
  String busca = '';

  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> sugestoes = [];

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
      final lista = await buscarSugestoesAdmin(idGerente: Sessao.idGerenteEfetivo);
      setState(() => sugestoes = lista.cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  List<Map<String, dynamic>> get sugestoesFiltradas {
    return sugestoes.where((s) {
      if (filtro != 'todos' && s['statusUi'] != filtro) return false;
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
              Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              TextButton(onPressed: _carregar, child: const Text('Tentar de novo', style: TextStyle(color: Cores.roxo, fontFamily: 'Poppins'))),
            ],
          ),
        ),
      );
    }
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma sugestão encontrada.',
          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins'),
        ),
      );
    }
    return RefreshIndicator(
      color: Cores.roxo,
      onRefresh: _carregar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: lista.length,
        itemBuilder: (context, i) => _cartaoSugestao(lista[i]),
      ),
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
                pillStatus((s['statusUi'] as String?) ?? 'pendente'),
                Text(
                  formatarData(s['dataAvaliacao'] as String?),
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tituloSugestao(s['comentario'] as String?),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Categoria: ${s['categoria'] ?? 'Sem categoria'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                (s['autor'] as String?) ?? 'Anônimo',
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
