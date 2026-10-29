//funções pra formatar textos (título, data, endereço)

//título da sugestão: os primeiros 90 caracteres do comentário
String tituloSugestao(String? comentario) {
  final texto = comentario?.trim() ?? '';
  if (texto.isEmpty) return 'Sugestão sem descrição';
  final limpo = texto.replaceAll(RegExp(r'\s+'), ' ');
  return limpo.length > 90 ? '${limpo.substring(0, 90)}…' : limpo;
}

//data relativa: "agora", "há 2h", "há 3d" ou "14/08/2026"
//converte do horário do servidor (UTC) pro horário do celular
String formatarData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final data = DateTime.tryParse(iso)?.toLocal();
  if (data == null) return '—';
  final horas = DateTime.now().difference(data).inHours;
  if (horas < 1) return 'agora';
  if (horas < 24) return 'há ${horas}h';
  final dias = horas ~/ 24;
  if (dias < 7) return 'há ${dias}d';
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

//data completa: "14/08/2026 | 10:00"
String formatarDataHora(String? iso) {
  final data = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (data == null) return '—';
  final dd = data.day.toString().padLeft(2, '0');
  final mm = data.month.toString().padLeft(2, '0');
  final hh = data.hour.toString().padLeft(2, '0');
  final min = data.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${data.year} | $hh:$min';
}

//converte pra true/false (a API às vezes manda 1/0, às vezes true/false)
bool? paraBool(dynamic valor) {
  if (valor == null) return null;
  if (valor is bool) return valor;
  if (valor is num) return valor != 0;
  return null;
}

//endereço numa linha: "Rua, Número - Bairro (Cidade/Estado)"
String formatarEndereco(Map<String, dynamic> estabelecimento) {
  final rua = (estabelecimento['rua'] as String?) ?? '';
  final numero = (estabelecimento['numero'] as String?) ?? '';
  final bairro = (estabelecimento['bairro'] as String?) ?? '';
  final cidade = (estabelecimento['cidade'] as String?) ?? '';
  final estado = (estabelecimento['estado'] as String?) ?? '';

  if (rua.isEmpty || numero.isEmpty) return 'Endereço não informado';

  final linha = bairro.isNotEmpty ? '$rua, $numero - $bairro' : '$rua, $numero';
  final cidadeEstado = [cidade, estado].where((s) => s.isNotEmpty).join('/');
  return cidadeEstado.isNotEmpty ? '$linha ($cidadeEstado)' : linha;
}
