import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cores.dart';
import 'api.dart';

// Mapa em tela cheia do estabelecimento — aberto pelo botão "Ver no mapa" na
// aba Sobre de infoLocal.dart (que não mostra mais mapa embutido). A
// geocodificação só acontece aqui, sob demanda, em vez de a cada abertura da
// tela de detalhes.
class MapaLocalPage extends StatefulWidget {
  final String nome;
  final String endereco;
  final String rua;
  final String numero;
  final String cidade;
  final String estado;
  final double? lat;
  final double? lng;

  const MapaLocalPage({
    super.key,
    required this.nome,
    required this.endereco,
    required this.rua,
    required this.numero,
    required this.cidade,
    required this.estado,
    this.lat,
    this.lng,
  });

  @override
  State<MapaLocalPage> createState() => _MapaLocalPageState();
}

class _MapaLocalPageState extends State<MapaLocalPage> {
  LatLng? _coords;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    if (widget.lat != null && widget.lng != null) {
      _coords = LatLng(widget.lat!, widget.lng!);
      _carregando = false;
    } else {
      _geocodificar();
    }
  }

  Future<void> _geocodificar() async {
    final coords = await buscarCoordenadasEndereco(
      rua: widget.rua,
      numero: widget.numero,
      cidade: widget.cidade,
      estado: widget.estado,
    );
    if (!mounted) return;
    setState(() {
      if (coords != null) _coords = LatLng(coords['lat']!, coords['lng']!);
      _carregando = false;
    });
  }

  Future<void> _abrirNoMaps() async {
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': widget.endereco});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.nome,
          style: const TextStyle(color: Colors.white, fontFamily: 'PoppinsSemi', fontSize: 16),
        ),
      ),
      body: _buildCorpo(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNoMaps,
        backgroundColor: Cores.roxoBotao,
        icon: const Icon(Icons.directions_outlined, color: Colors.white),
        label: const Text('Abrir no Maps', style: TextStyle(color: Colors.white, fontFamily: 'PoppinsSemi')),
      ),
    );
  }

  Widget _buildCorpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Cores.roxo));
    }

    final coords = _coords;
    if (coords == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(widget.endereco, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
              const SizedBox(height: 6),
              const Text(
                'Não foi possível localizar esse endereço no mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(initialCenter: coords, initialZoom: 16),
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
              child: const Icon(Icons.location_on, color: Cores.roxo, size: 44),
            ),
          ],
        ),
      ],
    );
  }
}
