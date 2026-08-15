import 'package:flutter/material.dart';
import 'infoLocal.dart';
import 'api.dart';
import 'sessao.dart';

class LocaisSalvosPage extends StatefulWidget {
  const LocaisSalvosPage({super.key});

  @override
  State<LocaisSalvosPage> createState() => _LocaisSalvosPageState();
}

class _LocaisSalvosPageState extends State<LocaisSalvosPage> {
  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> locais = [];

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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1A0A2E), size: 18),
                  ),
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

  // ─── Grid de locais ────────────────────────────────────────────────
  Widget _buildLocaisGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: locais.length,
        itemBuilder: (context, index) => _buildLocalCard(locais[index], index),
      ),
    );
  }

  // ─── Card do local ─────────────────────────────────────────────────
  Widget _buildLocalCard(Map<String, dynamic> local, int index) {
    final fotoUrl = urlFotoEstabelecimento(local['fotoPath'] as String?);
    final cidade = (local['cidade'] as String?) ?? '';
    final bairro = (local['bairro'] as String?) ?? '';
    final localizacao = [bairro, cidade].where((s) => s.isNotEmpty).join(', ');
    final nota = (local['mediaAvaliacoes'] as num?)?.toStringAsFixed(1) ?? '—';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InfoLocalPage(local: local)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E0E32),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagem ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: fotoUrl != null
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImagem(),
                          )
                        : _placeholderImagem(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ((local['categoria'] as String?) ?? '—').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removerSalvo(index),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59D0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Infos ────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (local['nome'] as String?) ?? 'Sem nome',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: "PoppinsSemi",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white38, size: 10),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            localizacao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 10,
                              fontFamily: "Poppins"
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A27),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFF4CAF50), size: 11),
                              const SizedBox(width: 2),
                              Text(
                                nota,
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImagem() {
    return Container(
      color: const Color(0xFF2A1A4A),
      child: const Icon(Icons.storefront, color: Colors.white38, size: 36),
    );
  }
}
