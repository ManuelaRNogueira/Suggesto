import 'package:flutter/material.dart';
import 'localCardCliente.dart';
import 'sugerir.dart';

//tela pra escolher o estabelecimento antes de fazer a sugestão
//(botão "Fazer sugestão" do Início)
class EscolherEstabelecimentoPage extends StatefulWidget {
  final List<Map<String, dynamic>> locais;

  const EscolherEstabelecimentoPage({super.key, required this.locais});

  @override
  State<EscolherEstabelecimentoPage> createState() =>
      _EscolherEstabelecimentoPageState();
}

class _EscolherEstabelecimentoPageState
    extends State<EscolherEstabelecimentoPage> {
  bool _pesquisando = false;
  final TextEditingController _pesquisaController = TextEditingController();
  String _termoPesquisa = '';

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  //filtro da pesquisa: mostra os locais com alguma palavra do nome
  //começando com o que foi digitado
  List<Map<String, dynamic>> get _locaisExibidos {
    if (_termoPesquisa.isEmpty) return widget.locais;
    final pesquisa = _termoPesquisa.toLowerCase();
    return widget.locais.where((local) {
      final nome = (local['nome'] as String?)?.toLowerCase() ?? '';
      final palavras = nome.split(' ');
      return palavras.any((palavra) => palavra.startsWith(pesquisa));
    }).toList();
  }

  //fecha a pesquisa e limpa o texto
  void _fecharPesquisa() {
    setState(() {
      _pesquisando = false;
      _termoPesquisa = '';
      _pesquisaController.clear();
    });
  }

  //rota pra tela de sugerir com o local escolhido
  void _escolher(Map<String, dynamic> local) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SugerirPage(local: local)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: Column(children: [_buildHeader(), Expanded(child: _corpo())]),
    );
  }

  // ─── Topo: voltar, título e botão de pesquisa ───────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8C8E8), Color(0xFFD4A8D8), Color(0xFFE8D0F0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1A0A2E),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_pesquisando)
                    Expanded(child: _buildCampoPesquisa())
                  else ...[
                    const Text(
                      'Fazer sugestão',
                      style: TextStyle(
                        color: Color(0xFF1A0A2E),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: "PoppinsBold",
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _pesquisando = true),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Color(0xFF1A0A2E),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Escolha o estabelecimento',
                  style: TextStyle(
                    color: const Color(0xFF1A0A2E).withOpacity(0.55),
                    fontSize: 13,
                    fontFamily: "PoppinsSemi",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //campo de pesquisa (aparece no lugar do título)
  Widget _buildCampoPesquisa() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF1A0A2E), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _pesquisaController,
              autofocus: true,
              onChanged: (texto) => setState(() => _termoPesquisa = texto),
              style: const TextStyle(
                color: Color(0xFF1A0A2E),
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Buscar estabelecimento',
                hintStyle: TextStyle(
                  color: const Color(0xFF1A0A2E).withOpacity(0.5),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _fecharPesquisa,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF1A0A2E),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lista de locais (vazia / sem resultado / cartões) ──────────────
  Widget _corpo() {
    if (widget.locais.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Nenhum estabelecimento cadastrado ainda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    final exibidos = _locaisExibidos;
    if (exibidos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Nenhum resultado para "$_termoPesquisa".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ...exibidos.map(
            (local) => cardEstabelecimentoCliente(
              local: local,
              salvo: false,
              onTap: () => _escolher(local),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
