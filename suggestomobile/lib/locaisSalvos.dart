import 'package:flutter/material.dart';
import 'infoLocal.dart';
import 'api.dart';
import 'sessao.dart';
import 'localCardCliente.dart';

class LocaisSalvosPage extends StatefulWidget {
  const LocaisSalvosPage({super.key});

  @override
  State<LocaisSalvosPage> createState() => _LocaisSalvosPageState();
}

class _LocaisSalvosPageState extends State<LocaisSalvosPage> {
  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> locais = [];

  // Busca inline no lugar da lupa — mesma estrutura da tela inicial, sem
  // navegar pra outra tela.
  bool _pesquisando = false;
  final TextEditingController _pesquisaController = TextEditingController();
  String _termoPesquisa = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // Mesma lógica de filtro usada na Home: separa o nome por palavras e
  // compara pelo início de cada uma.
  List<Map<String, dynamic>> get _locaisExibidos {
    if (_termoPesquisa.isEmpty) return locais;
    final pesquisa = _termoPesquisa.toLowerCase();
    return locais.where((local) {
      final nome = (local['nome'] as String?)?.toLowerCase() ?? '';
      final palavras = nome.split(' ');
      return palavras.any((palavra) => palavra.startsWith(pesquisa));
    }).toList();
  }

  void _fecharPesquisa() {
    setState(() {
      _pesquisando = false;
      _termoPesquisa = '';
      _pesquisaController.clear();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final lista = await buscarLocaisSalvos(Sessao.idUsuario!);
      setState(() => locais = lista.cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> _removerSalvo(int index) async {
    final idEstabelecimento = (locais[index]['idEstabelecimento'] as num?)?.toInt();
    if (idEstabelecimento == null || Sessao.idUsuario == null) return;
    try {
      await removerLocalSalvo(usuarioId: Sessao.idUsuario!, estabelecimentoId: idEstabelecimento);
      setState(() => locais.removeAt(index));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem, style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9B59D0)));
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
              TextButton(
                onPressed: _carregar,
                child: const Text('Tentar de novo', style: TextStyle(color: Color(0xFF9B59D0), fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF9B59D0),
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const SizedBox(height: 24),
            _buildSectionTitle(),
            const SizedBox(height: 16),
            if (locais.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Text('Você ainda não salvou nenhum local.', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
              )
            else if (_locaisExibidos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Text('Nenhum resultado para "$_termoPesquisa".', style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
              )
            else
              _buildLocaisGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB8C8E8),
            Color(0xFFD4A8D8),
            Color(0xFFE8D0F0),
          ],
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
                      'Locais Salvos',
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
                        child: const Icon(Icons.search, color: Color(0xFF1A0A2E), size: 18),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Sua coleção',
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

  // Campo de pesquisa — ocupa o espaço do título enquanto ativo.
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
              style: const TextStyle(color: Color(0xFF1A0A2E), fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Pesquisar local salvo',
                hintStyle: TextStyle(color: const Color(0xFF1A0A2E).withOpacity(0.5), fontFamily: 'Poppins', fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _fecharPesquisa,
            child: const Icon(Icons.close_rounded, color: Color(0xFF1A0A2E), size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Título da seção ───────────────────────────────────────────────
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Seus estabelecimentos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "PoppinsSemi",
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lista de locais (mesmo card e estrutura da Home) ──────────────
  Widget _buildLocaisGrid() {
    final exibidos = _locaisExibidos;
    return Column(
      children: exibidos.map((local) {
        final index = locais.indexOf(local);
        return _buildLocalCard(local, index);
      }).toList(),
    );
  }

  // ─── Card do local — componente compartilhado com a Home ───────────
  Widget _buildLocalCard(Map<String, dynamic> local, int index) {
    return cardEstabelecimentoCliente(
      local: local,
      salvo: true, // tudo aqui já está salvo, por definição da tela
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InfoLocalPage(local: local)),
        );
      },
      onToggleFavorito: () => _removerSalvo(index),
    );
  }
}
