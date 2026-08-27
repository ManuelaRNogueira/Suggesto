import 'package:flutter/material.dart';
import 'infoLocal.dart';
import 'api.dart';
import 'sessao.dart';
import 'localCardCliente.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> locais = [];
  Set<int> locaisSalvosIds = {};

  // Busca inline no lugar do botão da lupa — sem navegar pra outra tela.
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

  // Mesma lógica que existia na tela "Achar um estabelecimento": separa o
  // nome por palavras e compara pelo início de cada uma.
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
      final idUsuario = Sessao.idUsuario;
      final resultados = await Future.wait([
        buscarEstabelecimentos(),
        if (idUsuario != null) buscarLocaisSalvos(idUsuario) else Future.value(<dynamic>[]),
      ]);
      final lista = resultados[0];
      final salvos = resultados[1];
      setState(() {
        locais = lista.cast<Map<String, dynamic>>();
        locaisSalvosIds = salvos
            .map((e) => (e['idEstabelecimento'] as num?)?.toInt())
            .whereType<int>()
            .toSet();
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  // Mesmas chamadas que infoLocal.dart já usa pro botão de favorito lá —
  // sem duplicar lógica, só reaproveitando a API existente.
  Future<void> _alternarFavorito(int idEstabelecimento) async {
    final idUsuario = Sessao.idUsuario;
    if (idUsuario == null) return;

    final jaSalvo = locaisSalvosIds.contains(idEstabelecimento);
    setState(() {
      if (jaSalvo) {
        locaisSalvosIds.remove(idEstabelecimento);
      } else {
        locaisSalvosIds.add(idEstabelecimento);
      }
    });

    try {
      if (jaSalvo) {
        await removerLocalSalvo(usuarioId: idUsuario, estabelecimentoId: idEstabelecimento);
      } else {
        await salvarLocal(usuarioId: idUsuario, estabelecimentoId: idEstabelecimento);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (jaSalvo) {
          locaisSalvosIds.add(idEstabelecimento);
        } else {
          locaisSalvosIds.remove(idEstabelecimento);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem, style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      // ── Agora a tela inteira é rolável ─────────────────────────────
      body: RefreshIndicator(
        color: const Color(0xFF9B59D0),
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header agora rola junto com o restante ──────────────────
              _buildHeader(),

              /*const SizedBox(height: 16),

              // Botão "Solicitar algo"
              _buildSolicitarAlgo(),*/

              const SizedBox(height: 24),

              // Título + filtro
              _buildDescubraHeader(),

              const SizedBox(height: 12),

              // Lista de locais
              _buildCorpoLista(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────
      bottomNavigationBar: barraNavegacao(),
    );
  }

  Widget _buildCorpoLista() {
    if (carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF9B59D0))),
      );
    }
    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _carregar,
              child: const Text('Tentar de novo', style: TextStyle(color: Color(0xFF9B59D0), fontFamily: 'Poppins')),
            ),
          ],
        ),
      );
    }
    final exibidos = _locaisExibidos;
    if (exibidos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            _termoPesquisa.isEmpty ? 'Nenhum estabelecimento encontrado.' : 'Nenhum resultado para "$_termoPesquisa".',
            style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
          ),
        ),
      );
    }
    return Column(children: exibidos.map((local) => _buildLocalCard(local)).toList());
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft, 
          end: Alignment.centerRight,
          colors: [
            Color(0xFF88C3BE), 
            Color(0xFF839DCF), 
            Color(0xFFA6AADF), 
            Color(0xFFA9ADDA), 
            Color(0xFFB9BCE1), 
            Color(0xFFCED0EA), 
            Color(0xFFCED0EA), 
          ],
          stops: [0.0, 0.36, 0.51, 0.62, 0.73, 0.81, 0.89],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 140, 28), 
                  child: Text(
                    'Algo te desagradou?\nSugira uma melhoria!',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A), 
                      fontSize: 22,
                      fontFamily: 'PoppinsBold',
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 26,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _pesquisando ? _buildCampoPesquisa() : _buildBotaoPesquisa(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              right: 0,
              bottom: 80, 
              child: SizedBox(
                width: 175,
                height: 175,
                child: Image.asset(
                  'assets/images/imagemInicio.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botão de lupa — ao tocar, vira campo de pesquisa no mesmo lugar (sem
  // navegar pra outra tela).
  Widget _buildBotaoPesquisa() {
    return GestureDetector(
      onTap: () => setState(() => _pesquisando = true),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.search_rounded,
          size: 26,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  // Campo de pesquisa — mesmo tamanho/formato do botão que ele substitui.
  Widget _buildCampoPesquisa() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2D2D2D)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _pesquisaController,
              autofocus: true,
              onChanged: (texto) => setState(() => _termoPesquisa = texto),
              style: const TextStyle(color: Color(0xFF1A1A1A), fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Pesquisar estabelecimento',
                hintStyle: TextStyle(color: const Color(0xFF1A1A1A).withOpacity(0.5), fontFamily: 'Poppins', fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _fecharPesquisa,
            child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2D2D2D)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  /*Widget _buildSolicitarAlgo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2A1A4A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF4A2A7A),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16),
            Icon(
              Icons.notifications_outlined,
              color: Color(0xFFFFD700),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Solicitar algo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  // ─────────────────────────────────────────────────────────────────
  Widget _buildDescubraHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Descubra Novos Locais',
            style: TextStyle(
              color: Color.fromARGB(171, 255, 255, 255),
              fontSize: 18,
              fontFamily: 'PoppinsBold',
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A4A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _buildLocalCard(Map<String, dynamic> local) {
    final idEstabelecimento = (local['idEstabelecimento'] as num?)?.toInt();
    final salvo = idEstabelecimento != null && locaisSalvosIds.contains(idEstabelecimento);

    return cardEstabelecimentoCliente(
      local: local,
      salvo: salvo,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InfoLocalPage(local: local),
          ),
        );
      },
      onToggleFavorito: idEstabelecimento == null ? null : () => _alternarFavorito(idEstabelecimento),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  int paginaAtual = 0;
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