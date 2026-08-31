import 'dart:math';
import 'package:geolocator/geolocator.dart';

// Geolocalização do cliente + cálculo de distância — porte de
// "Suggesto - Web/Web/js/geoUtils.js", usado pra separar "Perto de você"
// (raio real) de "Descubra Novos Locais" na Home do mobile cliente. Não
// rastreia localização continuamente: pega a posição uma vez por carregamento
// da tela.

// Raio considerado "perto de você", em km. Único lugar pra mudar esse valor.
const double raioPertoKm = 5;

// Distância em linha reta entre duas coordenadas (fórmula de Haversine).
double calcularDistanciaKm(double lat1, double lng1, double lat2, double lng2) {
  const raioTerraKm = 6371.0;
  final dLat = _paraRadianos(lat2 - lat1);
  final dLng = _paraRadianos(lng2 - lng1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_paraRadianos(lat1)) *
          cos(_paraRadianos(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return raioTerraKm * c;
}

double _paraRadianos(double graus) => graus * pi / 180;

// Mesmo formato usado no card do site: "850 m" ou "1,2 km".
String formatarDistancia(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

// Pede a localização atual do dispositivo. Nunca lança exceção — permissão
// negada, GPS desligado, timeout ou qualquer outra falha tudo vira null, pra
// quem chama só precisar tratar "tenho localização" vs "não tenho" (mesmo
// comportamento do site, que também resolve null em vez de rejeitar).
Future<Position?> obterLocalizacaoUsuario() async {
  try {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) return null;

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  } catch (_) {
    return null;
  }
}
