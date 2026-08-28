import 'package:flutter/material.dart';
import 'api.dart';
import 'sessao.dart';

class LojasPontosPage extends StatefulWidget {
  const LojasPontosPage({super.key});

  @override
  State<LojasPontosPage> createState() => _LojasPontosPageState();
}

class _LojasPontosPageState extends State<LojasPontosPage> {
  int _faixaSelecionada = 0;

  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> _recompensas = [];
  int _meusPontos = 0;

  // Recompensas que esse cliente já resgatou — cada uma só pode ser resgatada
  // uma vez, então elas somem da vitrine (ver ResgateService no backend, que
  // também recusa um segundo resgate mesmo que a tela não tivesse escondido).
  Set<int> _idsResgatados = {};

  final List<String> _faixas = [
    'Até 6.000 pts',
    'Até 18.000 pts',
    'Até 25.000 pts',
    'Até 45.000 pts',
  ];

  final List<Map<String, dynamic>> _grupos = [
    {'label': 'Até 6.000 pts', 'faixaIndex': 0},
    {'label': 'Até 25.000 pts', 'faixaIndex': 2},
    {'label': 'Até 45.000 pts', 'faixaIndex': 3},
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
        buscarRecompensas(),
        buscarUsuario(Sessao.idUsuario!),
        buscarResgates(Sessao.idUsuario!),
      ]);
      final recompensas = resultados[0] as List<dynamic>;
      final usuario = resultados[1] as Map<String, dynamic>;
      final resgates = resultados[2] as List<dynamic>;
      setState(() {
        _idsResgatados = resgates
            .cast<Map<String, dynamic>>()
            .map((r) => (r['idRecompensa'] as num?)?.toInt())
            .whereType<int>()
            .toSet();
        _recompensas = recompensas
            .cast<Map<String, dynamic>>()
            .where((r) => !_idsResgatados.contains((r['id'] as num?)?.toInt()))
            .toList();
        _meusPontos = (usuario['pontos'] as num?)?.toInt() ?? 0;
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  // As "faixas" são só uma forma de agrupar as recompensas na tela por
  // faixa de custo em pontos — o backend não tem esse conceito, então
  // calculamos aqui a partir de custoPontos.
  int _faixaDoCusto(int custoPontos) {
    if (custoPontos <= 6000) return 0;
    if (custoPontos <= 18000) return 1;
    if (custoPontos <= 25000) return 2;
    return 3;
  }

  List<Map<String, dynamic>> _recompensasDaFaixa(int faixaIndex) {
    return _recompensas.where((r) {
      final custo = (r['custoPontos'] as num?)?.toInt() ?? 0;
      return _faixaDoCusto(custo) == faixaIndex;
    }).toList();
  }

  Future<void> _resgatarRecompensa(Map<String, dynamic> recompensa) async {
    final id = (recompensa['id'] as num?)?.toInt();
    if (id == null || Sessao.idUsuario == null) return;

    try {
      final resultado = await resgatar(usuarioId: Sessao.idUsuario!, recompensaId: id);
      if (!mounted) return;
      setState(() {
        _meusPontos = (resultado['novoSaldo'] as num?)?.toInt() ?? _meusPontos;
        _idsResgatados.add(id);
        _recompensas.removeWhere((r) => (r['id'] as num?)?.toInt() == id);
      });
      final codigo = resultado['codigoCupom']?.toString() ?? '';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E0E32),
          title: const Text('Resgate confirmado!', style: TextStyle(color: Colors.white, fontFamily: 'PoppinsBold')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Use o código abaixo no estabelecimento:', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59D0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF9B59D0).withOpacity(0.4)),
                ),
                child: Text(
                  codigo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9B59D0), fontSize: 16, fontFamily: 'PoppinsBold'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
            ),
          ],
        ),
      );
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
      body: SafeArea(bottom: false, child: _corpo()),
      bottomNavigationBar: barraNavegacao(),
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
            const SizedBox(height: 24),
            _buildPontosDestaque(),
            const SizedBox(height: 24),
            _buildFaixasTabs(),
            const SizedBox(height: 24),
            if (_recompensas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text('Nenhuma recompensa disponível no momento.', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
              )
            else
              ..._grupos.map((grupo) => _buildGrupoRecompensas(
                    grupo['label'] as String,
                    grupo['faixaIndex'] as int,
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPontosDestaque() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF88C3BE), Color(0xFFCED0EA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        child: Text(
          '${_formatarPontos(_meusPontos)} pts.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontFamily: 'PoppinsBold',
            height: 1,
          ),
        ),
      ),
    );
  }

  String _formatarPontos(int pts) {
    final s = pts.toString();
    if (s.length <= 3) return s;
    final List<String> partes = [];
    int i = s.length;
    while (i > 0) {
      partes.insert(0, s.substring(i - 3 < 0 ? 0 : i - 3, i));
      i -= 3;
    }
    return partes.join('.');
  }

  Widget _buildFaixasTabs() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _faixas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final isSelected = _faixaSelecionada == index;
          return GestureDetector(
            onTap: () => setState(() => _faixaSelecionada = index),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF4A2A7A) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _faixas[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontFamily: isSelected ? 'PoppinsSemi' : 'Poppins',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrupoRecompensas(String label, int faixaIndex) {
    final lista = _recompensasDaFaixa(faixaIndex);
    if (lista.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsBold',
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _buildRecompensaCard(lista[index]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRecompensaCard(Map<String, dynamic> recompensa) {
    final estabelecimento = recompensa['estabelecimento'] as Map<String, dynamic>?;
    final fotoPath = (recompensa['fotoPath'] as String?) ?? (estabelecimento?['fotoPath'] as String?);
    final fotoUrl = urlFotoEstabelecimento(fotoPath);
    final custo = (recompensa['custoPontos'] as num?)?.toInt() ?? 0;
    final titulo = (recompensa['nome'] as String?) ?? 'Recompensa';
    final parceiro = (estabelecimento?['nome'] as String?) ?? '';

    return GestureDetector(
      onTap: () => _mostrarDetalhes(recompensa),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: 110,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF2A1A4A),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fotoUrl != null)
                    Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.card_giftcard, color: Colors.white38, size: 36),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.card_giftcard, color: Colors.white38, size: 36),
                    ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 6, left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.generating_tokens,
                            color: Colors.white,
                            size: 9,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_formatarPontos(custo)} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontFamily: 'PoppinsSemi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              parceiro.isNotEmpty ? '$titulo - $parceiro' : titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> recompensa) {
    final estabelecimento = recompensa['estabelecimento'] as Map<String, dynamic>?;
    final fotoPath = (recompensa['fotoPath'] as String?) ?? (estabelecimento?['fotoPath'] as String?);
    final fotoUrl = urlFotoEstabelecimento(fotoPath);
    final titulo = (recompensa['nome'] as String?) ?? 'Recompensa';
    final parceiro = (estabelecimento?['nome'] as String?) ?? '—';
    final descricao = (recompensa['descricao'] as String?)?.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E0E32),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: fotoUrl != null
                    ? Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2A1A4A),
                          child: const Center(
                            child: Icon(Icons.card_giftcard,
                                color: Colors.white38, size: 48),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2A1A4A),
                        child: const Center(
                          child: Icon(Icons.card_giftcard,
                              color: Colors.white38, size: 48),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'PoppinsBold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parceiro,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B59D0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF9B59D0).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Disponível',
                    style: TextStyle(
                      color: Color(0xFF9B59D0),
                      fontSize: 12,
                      fontFamily: 'PoppinsBold',
                    ),
                  ),
                ),
              ],
            ),
            if (descricao != null && descricao.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                descricao,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resgatarRecompensa(recompensa);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59D0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Resgatar recompensa',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'PoppinsBold',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   int paginaAtual = 2;
  Widget barraNavegacao() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF12061E),
        border: Border(top: BorderSide(color: Color(0xFF1E0E32), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 0);
                  Navigator.pushNamed(context, '/home_cliente');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_filled,
                      color: paginaAtual == 0 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Início",
                      style: TextStyle(
                        color: paginaAtual == 0 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 1);
                  Navigator.pushNamed(context, '/minhasSugestoes');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum,
                      color: paginaAtual == 1 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Minhas\nSugestões",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: paginaAtual == 1 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 2);
                  Navigator.pushNamed(context, '/loja');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: paginaAtual == 2 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Pontos",
                      style: TextStyle(
                        color: paginaAtual == 2 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 3);
                  Navigator.pushNamed(context, '/perfil');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: paginaAtual == 3 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Perfil",
                      style: TextStyle(
                        color: paginaAtual == 3 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
