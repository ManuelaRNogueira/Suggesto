import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'statusSugestao.dart';
import 'api.dart';
import 'sessao.dart';
import 'sugerir.dart';
import 'mapaLocal.dart';

class InfoLocalPage extends StatefulWidget {
  final Map<String, dynamic> local;

  const InfoLocalPage({super.key, required this.local});

  @override
  State<InfoLocalPage> createState() => _InfoLocalPageState();
}

class _InfoLocalPageState extends State<InfoLocalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isFavorito = false;

  int? _idEstabelecimento;
  late String _nome;
  late String _bairro;
  late String _categoria;
  late String? _imagem;
  late String _rua;
  late String _numero;
  late String _cidade;
  late String _estado;
  late String _endereco;
  late String _horario;
  late String _telefone;
  late String? _sobre;
  double? _lat;
  double? _lng;

  int _abaAtual = 0; // 0 = Sugestões, 1 = Sobre

  bool _carregandoAvaliacoes = true;
  List<Map<String, dynamic>> _avaliacoes = [];

  @override
  void initState() {
    super.initState();

    final local = widget.local;

    _idEstabelecimento = (local['idEstabelecimento'] as num?)?.toInt();
    _nome = (local['nome'] as String?) ?? 'Local';
    _categoria = (local['categoria'] as String?) ?? '';
    final cidade = (local['cidade'] as String?) ?? '';
    final bairroLocal = (local['bairro'] as String?) ?? '';
    _bairro = [bairroLocal, cidade].where((s) => s.isNotEmpty).join(', ');
    if (_bairro.isEmpty) _bairro = 'Campinas, SP';
    _imagem = urlFotoEstabelecimento(local['fotoPath'] as String?);

    _rua = (local['rua'] as String?) ?? '';
    _numero = (local['numero'] as String?) ?? '';
    _cidade = cidade;
    _estado = (local['estado'] as String?) ?? '';
    final partesEndereco = <String>[
      if (_rua.isNotEmpty) _numero.isNotEmpty ? '$_rua, $_numero' : _rua,
      if (bairroLocal.isNotEmpty) bairroLocal,
      if (cidade.isNotEmpty) cidade,
      if (_estado.isNotEmpty) _estado,
    ];
    _endereco = partesEndereco.isNotEmpty ? partesEndereco.join(' - ') : 'Endereço não informado';

    _horario = (local['horarioFuncionamento'] as String?)?.isNotEmpty == true
        ? local['horarioFuncionamento'] as String
        : 'Horário não informado';
    _telefone = (local['telefone'] as String?)?.isNotEmpty == true
        ? local['telefone'] as String
        : 'Telefone não informado';
    // Sem fallback inventado — se o estabelecimento não preencheu, a seção
    // "Sobre o local" simplesmente não aparece (ver _buildAbaSobre).
    final sobreBruto = (local['sobre'] as String?)?.trim();
    _sobre = (sobreBruto == null || sobreBruto.isEmpty) ? null : sobreBruto;

    // Sem mapa embutido na tela de detalhes — lat/lng só é usado se o
    // usuário pedir pra ver o mapa (ver mapaLocal.dart), então só guardamos
    // aqui, sem geocodificar nada de cara.
    final lat = local['lat'];
    final lng = local['lng'];
    _lat = lat == null ? null : (lat as num).toDouble();
    _lng = lng == null ? null : (lng as num).toDouble();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_fadeAnim);

    _animController.forward();

    _verificarFavorito();
    _carregarAvaliacoes();
  }

  // Confere se esse local já está nos salvos do usuário, só pra deixar o
  // ícone certo ao abrir a tela — falha silenciosa, não é essencial.
  Future<void> _verificarFavorito() async {
    if (_idEstabelecimento == null || Sessao.idUsuario == null) return;
    try {
      final salvos = await buscarLocaisSalvos(Sessao.idUsuario!);
      final salvo = salvos.any((e) => (e['idEstabelecimento'] as num?)?.toInt() == _idEstabelecimento);
      if (mounted) setState(() => _isFavorito = salvo);
    } catch (_) {
      // Ignora — o botão de favorito ainda funciona, só começa desmarcado.
    }
  }

  Future<void> _alternarFavorito() async {
    if (_idEstabelecimento == null || Sessao.idUsuario == null) return;
    final novoValor = !_isFavorito;
    setState(() => _isFavorito = novoValor);
    try {
      if (novoValor) {
        await salvarLocal(usuarioId: Sessao.idUsuario!, estabelecimentoId: _idEstabelecimento!);
      } else {
        await removerLocalSalvo(usuarioId: Sessao.idUsuario!, estabelecimentoId: _idEstabelecimento!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isFavorito = !novoValor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem), backgroundColor: Colors.redAccent),
      );
    }
  }

  // GET /api/avaliacoes/estabelecimento/{id} — mesmas avaliações que
  // alimentam a aba "Sugestões" da tela equivalente na Web
  // (estabelecimentoCli.js / renderizarSugestoes).
  Future<void> _carregarAvaliacoes() async {
    final id = _idEstabelecimento;
    if (id == null) {
      if (mounted) setState(() => _carregandoAvaliacoes = false);
      return;
    }
    try {
      final lista = (await buscarAvaliacoesEstabelecimento(id)).cast<Map<String, dynamic>>();
      lista.sort((a, b) => (b['dataAvaliacao'] as String? ?? '').compareTo(a['dataAvaliacao'] as String? ?? ''));
      if (!mounted) return;
      setState(() => _avaliacoes = lista);
    } catch (_) {
      // Falha silenciosa — a aba mostra "nenhuma sugestão" em vez de travar.
    } finally {
      if (mounted) setState(() => _carregandoAvaliacoes = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _buildTopoVoltar(),
                _buildTopInfoRow(),
                const Divider(color: Cores.borda, height: 1),
                _buildAbasSeletor(),
                Expanded(
                  child: _abaAtual == 0 ? _buildAbaSugestoes() : _buildAbaSobre(),
                ),
                _buildBotaoFixo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopoVoltar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Cores.cartao,
                shape: BoxShape.circle,
                border: Border.all(color: Cores.borda),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoRow() {
    final subtitulo = [_categoria, _bairro].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imagem != null
                ? Image.network(_imagem!,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoPlaceholder())
                : _logoPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nome,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold, fontFamily: "PoppinsSemi")),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: "Poppins")),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _alternarFavorito,
            icon: Icon(
              _isFavorito ? Icons.bookmark : Icons.bookmark_border,
              color: Cores.roxo,
            ),
          )
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Cores.borda,
      child: const Icon(Icons.storefront, color: Colors.white38),
    );
  }

  // ── Seletor de abas (pílulas, mesmo padrão de _chip em sugestoesAdm.dart) ──

  Widget _buildAbasSeletor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(child: _abaPill('Sugestões', 0)),
          const SizedBox(width: 10),
          Expanded(child: _abaPill('Sobre', 1)),
        ],
      ),
    );
  }

  Widget _abaPill(String rotulo, int indice) {
    final ativa = _abaAtual == indice;
    return GestureDetector(
      onTap: () => setState(() => _abaAtual = indice),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ativa ? Cores.roxo : Cores.campo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: ativa ? Colors.white : Colors.white70,
            fontSize: 13,
            fontFamily: 'PoppinsSemi',
            fontWeight: ativa ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Aba Sugestões ──────────────────────────────────────────────────────

  Widget _buildAbaSugestoes() {
    if (_carregandoAvaliacoes) {
      return const Center(child: CircularProgressIndicator(color: Cores.roxo));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumoNota(),
          const SizedBox(height: 14),
          if (_avaliacoes.isEmpty)
            _buildVazioSugestoes()
          else
            for (final a in _avaliacoes) _buildCardSugestao(a),
        ],
      ),
    );
  }

  Widget _buildResumoNota() {
    final total = _avaliacoes.length;
    final soma = _avaliacoes.fold<double>(0, (acc, a) => acc + ((a['nota'] as num?)?.toDouble() ?? 0));
    final media = total > 0 ? soma / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        children: [
          Text(
            total > 0 ? media.toStringAsFixed(1) : '—',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'PoppinsBold', fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < media.round() ? Icons.star : Icons.star_border,
                    color: Cores.amarelo,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$total ${total == 1 ? 'avaliação' : 'avaliações'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVazioSugestoes() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.forum_outlined, color: Colors.white24, size: 36),
            const SizedBox(height: 10),
            const Text('Nenhuma sugestão ainda.', style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            const Text('Seja o primeiro a avaliar esse local.', style: TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSugestao(Map<String, dynamic> a) {
    final usuario = a['usuario'] as Map<String, dynamic>?;
    final nomeUsuario = (usuario?['nome'] as String?) ?? 'Usuário';
    final nota = (a['nota'] as num?)?.toInt() ?? 0;
    final categoriaNome = ((a['categoria'] as Map<String, dynamic>?)?['nomeCategoria'] as String?) ?? 'Geral';
    final tipoInfo = _estiloTipo((a['tipo'] as String?) ?? 'sugestao');
    final status = ((a['status'] as String?) ?? 'pendente').toLowerCase();
    final comentario = a['comentario'] as String?;
    final resposta = a['resposta'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Cores.tag,
                child: Text(
                  _iniciais(nomeUsuario),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomeUsuario, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600)),
                    Text(formatarData(a['dataAvaliacao'] as String?), style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              pillStatus(status, fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(i < nota ? Icons.star : Icons.star_border, color: Cores.amarelo, size: 14)),
              ),
              _tagPequena(tipoInfo.$1, tipoInfo.$2),
              _tagPequena(categoriaNome, Cores.roxo),
            ],
          ),
          if (comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comentario, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins', height: 1.4)),
          ],
          if (resposta != null && resposta.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCaixaResposta(resposta),
          ],
        ],
      ),
    );
  }

  // Caixa de resposta com destaque: fundo levemente tingido de roxo, barra
  // vertical sólida colada na esquerda e título em roxo claro com ícone de
  // loja — pra dar hierarquia de "isso é a voz do estabelecimento".
  Widget _buildCaixaResposta(String resposta) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Cores.roxo.withOpacity(0.10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: Cores.roxo),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, color: Cores.roxo, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'RESPOSTA DO ESTABELECIMENTO',
                            style: TextStyle(
                              color: Cores.roxo,
                              fontSize: 10.5,
                              fontFamily: 'PoppinsSemi',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resposta,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontFamily: 'Poppins', height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagPequena(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 10, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600)),
    );
  }

  // Tipo do feedback (elogio/crítica/sugestão) — o mesmo conceito de
  // TIPOS_FEEDBACK em "Suggesto - Web/Web/js/avaliacoesUtils.js".
  (String, Color) _estiloTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'elogio':
        return ('Elogio', Cores.verde);
      case 'critica':
        return ('Crítica', Cores.vermelho);
      default:
        return ('Sugestão', Cores.roxo);
    }
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    var ini = partes.first[0].toUpperCase();
    if (partes.length > 1) ini += partes.last[0].toUpperCase();
    return ini;
  }

  // ── Aba Sobre ──────────────────────────────────────────────────────────

  Widget _buildAbaSobre() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sobre != null) ...[
            const Text('Sobre o local', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_sobre!, style: const TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Poppins', height: 1.5)),
            const SizedBox(height: 18),
          ],
          _buildCardEndereco(),
          const SizedBox(height: 10),
          _cardSobreItem(Icons.schedule_outlined, 'Horário de funcionamento', _horario, Cores.verde),
          const SizedBox(height: 10),
          _cardSobreItem(Icons.phone_outlined, 'Telefone', _telefone, Cores.azul),
        ],
      ),
    );
  }

  Widget _buildCardEndereco() {
    final temEndereco = _endereco != 'Endereço não informado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Cores.roxo.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_outlined, color: Cores.roxo, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Endereço', style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins')),
                    const SizedBox(height: 3),
                    Text(_endereco, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins', height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          if (temEndereco) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirNoMaps,
                    icon: const Icon(Icons.directions_outlined, size: 16, color: Cores.roxo),
                    label: const Text('Abrir no Maps', style: TextStyle(color: Cores.roxo, fontFamily: 'PoppinsSemi', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Cores.roxo),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirMapaInterno,
                    icon: const Icon(Icons.map_outlined, size: 16, color: Colors.white70),
                    label: const Text('Ver no mapa', style: TextStyle(color: Colors.white70, fontFamily: 'PoppinsSemi', fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Cores.borda),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Endereço em texto — o Google Maps geocodifica sozinho ao abrir o link,
  // não precisa da Nominatim aqui (só o mapa embutido usa, ver mapaLocal.dart).
  Future<void> _abrirNoMaps() async {
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': _endereco});
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.', style: TextStyle(fontFamily: 'Poppins'))),
      );
    }
  }

  void _abrirMapaInterno() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaLocalPage(
          nome: _nome,
          endereco: _endereco,
          rua: _rua,
          numero: _numero,
          cidade: _cidade,
          estado: _estado,
          lat: _lat,
          lng: _lng,
        ),
      ),
    );
  }

  Widget _cardSobreItem(IconData icone, String rotulo, String valor, Color cor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: cor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins')),
                const SizedBox(height: 3),
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins', height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botão fixo no rodapé ──────────────────────────────────────────────

  Widget _buildBotaoFixo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.roxoBotao,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SugerirPage(local: widget.local)),
            );
          },
          child: const Text(
            "Fazer Sugestão",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: "PoppinsSemi", fontSize: 15),
          ),
        ),
      ),
    );
  }
}
