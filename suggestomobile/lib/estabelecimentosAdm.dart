import 'package:flutter/material.dart';
import 'cores.dart';
import 'sessao.dart';
import 'api.dart';
import 'detalhesEstabelecimentoAdm.dart';
import 'cartaoEstabelecimentoAdm.dart';

//tela de lista dos estabelecimentos do admin (só consulta, sem editar)
class EstabelecimentosAdm extends StatefulWidget {
  const EstabelecimentosAdm({super.key});

  @override
  State<EstabelecimentosAdm> createState() => _EstabelecimentosAdmState();
}

class _EstabelecimentosAdmState extends State<EstabelecimentosAdm> {
  //aba marcada na barra de baixo (2 = Locais)
  int paginaAtual = 2;

  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> estabelecimentos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  //busca os estabelecimentos do gerente logado
  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final lista = await buscarEstabelecimentosVinculados(
        idGerente: Sessao.idUsuario,
      );
      setState(() => estabelecimentos = lista);
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  //rota pro detalhe do estabelecimento
  void _abrirDetalhes(Map<String, dynamic> estabelecimento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetalhesEstabelecimentoAdm(estabelecimento: estabelecimento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Estabelecimentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'PoppinsBold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _corpo()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  //carregando / erro com "tentar de novo" / lista vazia / lista (puxar pra baixo atualiza)
  Widget _corpo() {
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
    if (estabelecimentos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum estabelecimento cadastrado.',
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
        itemCount: estabelecimentos.length,
        itemBuilder: (context, i) => cartaoEstabelecimentoAdm(
          estabelecimentos[i],
          onTap: () => _abrirDetalhes(estabelecimentos[i]),
        ),
      ),
    );
  }

  //barra de baixo: rotas pro Início, Sugestões, Locais e Perfil
  Widget _buildBarraNavegacao() {
    final abas = [
      _Aba('Início', Icons.home_filled, '/inicioAdm'),
      _Aba('Sugestões', Icons.forum, '/sugestoesAdm'),
      _Aba('Locais', Icons.storefront, '/estabelecimentosAdm'),
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

  //um botão da barra (não navega se já está nessa tela)
  Widget _itemNavegacao(_Aba aba, int indice) {
    final ativo = paginaAtual == indice;
    return GestureDetector(
      onTap: () {
        setState(() => paginaAtual = indice);
        if (aba.rota != '/estabelecimentosAdm')
          Navigator.pushNamed(context, aba.rota);
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

//dados de uma aba: nome, ícone e rota
class _Aba {
  final String rotulo;
  final IconData icone;
  final String rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
