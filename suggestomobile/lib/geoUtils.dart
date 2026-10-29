import 'dart:math';
import 'package:geolocator/geolocator.dart';

//localização do usuário e cálculo de distância

//raio do "Perto de você", em km
const double raioPertoKm = 5;

//cálculo: distância em km entre dois pontos (fórmula de Haversine)
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

//graus → radianos (usado no cálculo acima)
double _paraRadianos(double graus) => graus * pi / 180;

//distância em texto: "850 m" ou "1,2 km"
String formatarDistancia(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

//localização pro check-in (precisa ser precisa)
//se falhar, devolve a mensagem dizendo o que fazer (ligar GPS, permitir ou usar o QR)
Future<({Position? posicao, String? erro})> obterLocalizacaoParaCheckin() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (posicao: null, erro: 'Ligue a localização do celular ou leia o QR de check-in do local.');
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
      return (
        posicao: null,
        erro: 'Você não permitiu o acesso à localização. Permita nas configurações ou leia o QR de check-in do local.',
      );
    }
    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (posicao: posicao, erro: null);
  } catch (_) {
    return (posicao: null, erro: 'Não conseguimos pegar sua localização. Tente de novo ou leia o QR do local.');
  }
}

//localização pra mostrar os locais próximos
//se der qualquer problema devolve null (não lança erro)
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
