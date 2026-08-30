import 'package:flutter/material.dart';
import 'infoLocal.dart';
import 'api.dart';
import 'sessao.dart';
import 'localCardCliente.dart';
import 'qrScanner.dart';
import 'sugerir.dart';
import 'escolherEstabelecimento.dart';

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

  // Filtro de categorias — usa as categorias reais dos locais já carregados.
  final Set<String> _categoriasSelecionadas = {};

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
    Iterable<Map<String, dynamic>> resultado = locais;
    if (_categoriasSelecionadas.isNotEmpty) {
      resultado = resultado.where(
        (local) => _categoriasSelecionadas.contains(
          (local['categoria'] as String?) ?? '',
        ),
      );
    }
    if (_termoPesquisa.isNotEmpty) {
      final pesquisa = _termoPesquisa.toLowerCase();
      resultado = resultado.where((local) {
        final nome = (local['nome'] as String?)?.toLowerCase() ?? '';
        final palavras = nome.split(' ');
        return palavras.any((palavra) => palavra.startsWith(pesquisa));
      });
    }
    return resultado.toList();
  }

  // Categorias reais existentes entre os locais já carregados — usadas
  // como opções no filtro, sem depender de nenhuma lista fixa.
  List<String> get _categoriasDisponiveis {
    final categorias = <String>{};
    for (final local in locais) {
      final c = (local['categoria'] as String?)?.trim();
      if (c != null && c.isNotEmpty) categorias.add(c);
    }
    final lista = categorias.toList()..sort();
    return lista;
  }

  void _fecharPesquisa() {
    setState(() {
      _pesquisando = false;
      _termoPesquisa = '';
      _pesquisaController.clear();
    });
  }

  Future<void> _abrirScannerQr() async {
    final conteudo = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (!mounted || conteudo == null) return;

    final idEstabelecimento = _extrairIdEstabelecimento(conteudo);
    if (idEstabelecimento == null) {
      _mostrarErroQr('Este QR Code não pertence a um estabelecimento.');
      return;
    }

    Map<String, dynamic>? local;
    for (final item in locais) {
      if ((item['idEstabelecimento'] as num?)?.toInt() == idEstabelecimento) {
        local = item;
        break;
      }
    }

    try {
      local ??= await buscarEstabelecimento(idEstabelecimento);
    } on ApiException catch (e) {
      if (mounted) _mostrarErroQr(e.mensagem);
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SugerirPage(local: local)));
  }

  int? _extrairIdEstabelecimento(String conteudo) {
    final valor = conteudo.trim();
    final idDireto = int.tryParse(valor);
    if (idDireto != null) return idDireto;

    final uri = Uri.tryParse(valor);
    if (uri != null) {
      final parametro =
          uri.queryParameters['id'] ??
          uri.queryParameters['idEstabelecimento'] ??
          uri.queryParameters['estabelecimentoId'];
      final idParametro = int.tryParse(parametro ?? '');
      if (idParametro != null) return idParametro;

      if (uri.pathSegments.isNotEmpty) {
        final idNoCaminho = int.tryParse(uri.pathSegments.last);
        if (idNoCaminho != null) return idNoCaminho;
      }
    }

    final correspondencia = RegExp(
      r'(?:idEstabelecimento|estabelecimentoId|id)[=:/](\d+)',
      caseSensitive: false,
    ).firstMatch(valor);
    return int.tryParse(correspondencia?.group(1) ?? '');
  }

  void _mostrarErroQr(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.redAccent,
      ),
    );
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
        if (idUsuario != null)
          buscarLocaisSalvos(idUsuario)
        else
          Future.value(<dynamic>[]),
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
        await removerLocalSalvo(
          usuarioId: idUsuario,
          estabelecimentoId: idEstabelecimento,
        );
      } else {
        await salvarLocal(
          usuarioId: idUsuario,
          estabelecimentoId: idEstabelecimento,
        );
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
        SnackBar(
          content: Text(
            e.mensagem,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
        ),
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
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF9B59D0)),
        ),
      );
    }
    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
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
                style: TextStyle(
                  color: Color(0xFF9B59D0),
                  fontFamily: 'Poppins',
                ),
              ),
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
            _termoPesquisa.isEmpty
                ? 'Nenhum estabelecimento encontrado.'
                : 'Nenhum resultado para "$_termoPesquisa".',
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }
    return Column(
      children: exibidos.map((local) => _buildLocalCard(local)).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A0A3A),
                    Color(0xFF2D1060),
                    Color(0xFF1A0A3A),
                  ],
                  stops: [0, 0.5, 1],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x406366F1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 60,
                    spreadRadius: 4,
                    offset: Offset(-30, -20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Algo te desagradou?\nSugira uma melhoria!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sua opinião transforma experiências. Envie uma sugestão agora e ajude os lugares que você frequenta a melhorarem.',
                    style: TextStyle(
                      color: Color(0xA6FFFFFF),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      // Mesma função do botão do banner no site (abrirSugestao
                      // em js/inicioCli.js): manda pra uma página com todas as
                      // opções de estabelecimento, não só abre a busca inline.
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EscolherEstabelecimentoPage(locais: locais),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Color(0xFF7C3AED),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Fazer sugestão',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _abrirScannerQr,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1924),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x12FFFFFF)),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 24,
                      color: Color(0xFFF0F0F8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pesquisando
                      ? _buildCampoPesquisa()
                      : _buildBotaoPesquisa(),
                ),
              ],
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
          color: const Color(0xFF1A1924),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 22, color: Color(0x8CF0F0F8)),
            SizedBox(width: 8),
            Text(
              'Buscar estabelecimento...',
              style: TextStyle(
                color: Color(0x8CF0F0F8),
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ],
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
        color: const Color(0xFF1A1924),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0x8CF0F0F8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _pesquisaController,
              autofocus: true,
              onChanged: (texto) => setState(() => _termoPesquisa = texto),
              style: const TextStyle(
                color: Color(0xFFF0F0F8),
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Pesquisar estabelecimento',
                hintStyle: const TextStyle(
                  color: Color(0x8CF0F0F8),
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
              size: 20,
              color: Color(0x8CF0F0F8),
            ),
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
          GestureDetector(
            onTap: _abrirFiltro,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A4A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Filtro por categoria — bottom sheet igual ao já usado em lojaPontos.dart,
  // com os chips no mesmo estilo dos filtros do painel adm (sugestoesAdm.dart).
  // Aplica o filtro em tempo real na lista, sem abrir nova tela.
  void _abrirFiltro() {
    final categorias = _categoriasDisponiveis;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          void alternar(String categoria) {
            setModalState(() {
              setState(() {
                if (_categoriasSelecionadas.contains(categoria)) {
                  _categoriasSelecionadas.remove(categoria);
                } else {
                  _categoriasSelecionadas.add(categoria);
                }
              });
            });
          }

          void limpar() {
            setModalState(
              () => setState(() => _categoriasSelecionadas.clear()),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E0E32),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar por categoria',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PoppinsBold',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_categoriasSelecionadas.isNotEmpty)
                      GestureDetector(
                        onTap: limpar,
                        child: const Text(
                          'Limpar filtros',
                          style: TextStyle(
                            color: Color(0xFF9B59D0),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (categorias.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nenhuma categoria disponível.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorias.map((c) {
                      final ativo = _categoriasSelecionadas.contains(c);
                      return GestureDetector(
                        onTap: () => alternar(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ativo
                                ? const Color(0xFF9B59D0)
                                : const Color(0xFF2A1A4A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ativo
                                  ? const Color(0xFF9B59D0)
                                  : const Color(0xFF3A2A5A),
                            ),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: ativo ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: ativo
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _buildLocalCard(Map<String, dynamic> local) {
    final idEstabelecimento = (local['idEstabelecimento'] as num?)?.toInt();
    final salvo =
        idEstabelecimento != null &&
        locaisSalvosIds.contains(idEstabelecimento);

    return cardEstabelecimentoCliente(
      local: local,
      salvo: salvo,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InfoLocalPage(local: local)),
        );
      },
      onToggleFavorito: idEstabelecimento == null
          ? null
          : () => _alternarFavorito(idEstabelecimento),
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
