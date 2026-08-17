import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api.dart';
import 'sessao.dart';
import 'sugerir.dart';

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

  // O backend não tem latitude/longitude cadastrada pra nenhum
  // estabelecimento — usamos direto se um dia existir, senão geocodificamos
  // o endereço via Nominatim (ver _geocodificarEndereco / _buildMap).
  LatLng? _localCoords;
  bool _carregandoMapa = true;

  int? _idEstabelecimento;
  late String _nome;
  late String _bairro;
  late String? _imagem;
  late String _endereco;
  late String _horario;
  late String _telefone;
  late String _descricao;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();

    final local = widget.local;

    _idEstabelecimento = (local['idEstabelecimento'] as num?)?.toInt();
    _nome = (local['nome'] as String?) ?? 'Local';
    final cidade = (local['cidade'] as String?) ?? '';
    final bairroLocal = (local['bairro'] as String?) ?? '';
    _bairro = [bairroLocal, cidade].where((s) => s.isNotEmpty).join(', ');
    if (_bairro.isEmpty) _bairro = 'Campinas, SP';
    _imagem = urlFotoEstabelecimento(local['fotoPath'] as String?);

    final rua = (local['rua'] as String?) ?? '';
    final numero = (local['numero'] as String?) ?? '';
    final partesEndereco = <String>[
      if (rua.isNotEmpty) numero.isNotEmpty ? '$rua, $numero' : rua,
      if (bairroLocal.isNotEmpty) bairroLocal,
      if (cidade.isNotEmpty) cidade,
      if ((local['estado'] as String?)?.isNotEmpty == true) local['estado'] as String,
    ];
    _endereco = partesEndereco.isNotEmpty ? partesEndereco.join(' - ') : 'Endereço não informado';

    _horario = (local['horarioFuncionamento'] as String?)?.isNotEmpty == true
        ? local['horarioFuncionamento'] as String
        : 'Horário não informado';
    _telefone = (local['telefone'] as String?)?.isNotEmpty == true
        ? local['telefone'] as String
        : 'Telefone não informado';
    _descricao = (local['sobre'] as String?)?.isNotEmpty == true
        ? local['sobre'] as String
        : 'Um dos estabelecimentos mais bem avaliados da região.';
    _tags = (local['tags'] as List<String>?) ?? ['Wi-Fi', 'Estacionamento'];

    // Se o estabelecimento já vier com lat/lng do backend, usa direto;
    // senão geocodifica o endereço via Nominatim (ver _geocodificarEndereco).
    final lat = local['lat'];
    final lng = local['lng'];
    if (lat != null && lng != null) {
      _localCoords = LatLng((lat as num).toDouble(), (lng as num).toDouble());
      _carregandoMapa = false;
    } else {
      _geocodificarEndereco(rua: rua, numero: numero, cidade: cidade, estado: (local['estado'] as String?) ?? '');
    }

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

  Future<void> _geocodificarEndereco({
    required String rua,
    required String numero,
    required String cidade,
    required String estado,
  }) async {
    final coords = await buscarCoordenadasEndereco(rua: rua, numero: numero, cidade: cidade, estado: estado);
    if (!mounted) return;
    setState(() {
      if (coords != null) {
        _localCoords = LatLng(coords['lat']!, coords['lng']!);
      }
      _carregandoMapa = false;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: Stack(
        children: [
          _buildMap(),

          // painel por cima
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildInfoPanel(),
              ),
            ),
          ),

          // botão voltar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A2E).withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
  // Enquanto o endereço ainda está sendo geocodificado (Nominatim) — mesmo
  // skeleton simples usado no resto do app pra estados de carregamento.
  if (_carregandoMapa) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1A0A2E),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF9B59D0)),
      ),
    );
  }

  final coords = _localCoords;
  // Geocodificação falhou (endereço não encontrado, sem internet, etc.) —
  // mostra só o endereço no lugar do mapa, em vez de travar a tela.
  if (coords == null) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1A0A2E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF9B59D0), size: 48),
              const SizedBox(height: 12),
              Text(
                _endereco,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontFamily: "Poppins"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final adjustedCenter = LatLng(
    coords.latitude - 0.0055,
    coords.longitude,
  );

  return SizedBox(
    height: MediaQuery.of(context).size.height,
    child: FlutterMap(
      options: MapOptions(
        initialCenter: adjustedCenter,
        initialZoom: 15.5,
      ),
      children: [
        TileLayer(
          // Tile padrão do OpenStreetMap — gratuito, sem chave de API.
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.suggesto.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: coords,
              width: 60,
              height: 60,
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF9B59D0),
                size: 44,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildInfoPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFF1A0A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // puxador
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            _buildTopInfoRow(),
            const Divider(color: Color(0xFF2A1A4A)),

            _buildDetalhesList(),
            _buildDescricao(),
            _buildTagsRow(),
            _buildBotoes(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imagem != null
                ? Image.network(_imagem!,
                    width: 60, height: 60, fit: BoxFit.cover,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold, fontFamily: "PoppinsSemi")),
                Text(_bairro,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins")),
              ],
            ),
          ),
          IconButton(
            onPressed: _alternarFavorito,
            icon: Icon(
              _isFavorito ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFF9B59D0),
            ),
          )
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFF2A1A4A),
      child: const Icon(Icons.storefront, color: Colors.white38),
    );
  }

  Widget _buildDetalhesList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_endereco, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(_horario, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(_telefone, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDescricao() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(_descricao,
          style: const TextStyle(color: Colors.white60),),
    );
  }

  Widget _buildTagsRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: _tags
            .map((e) => Chip(
                  label: Text(e),
                  backgroundColor: const Color(0xFF2A1A4A),
                  labelStyle: const TextStyle(color: Colors.white70),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBotoes() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 57, 0, 103),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SugerirPage(local: widget.local)),
          );
        },
        child: const Text(
          "Fazer Sugestão",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(229, 212, 212, 212), fontFamily: "Poppins"),
        ),
      ),
    );
  }
}
