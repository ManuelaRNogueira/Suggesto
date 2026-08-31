// Formatação de texto usada nas telas de sugestão — porte de
// Suggesto_DesktopReact/renderer/src/api/admin.js (tituloSugestao / formatarData),
// pra ficar igual em todas as plataformas.

// A sugestão não tem campo de título no banco — só "comentario". Usamos a
// primeira parte do texto como título, igual o painel admin do desktop faz.
String tituloSugestao(String? comentario) {
  final texto = comentario?.trim() ?? '';
  if (texto.isEmpty) return 'Sugestão sem descrição';
  final limpo = texto.replaceAll(RegExp(r'\s+'), ' ');
  return limpo.length > 90 ? '${limpo.substring(0, 90)}…' : limpo;
}

// "2026-08-14T10:00:00Z" -> "há 2h" / "há 3d" / "14/08/2026".
// O servidor sempre manda a data no horário de Greenwich (UTC) — tipo o
// horário "de fábrica". Aqui a gente converte pro horário local do
// celular antes de mostrar, senão a hora apareceria errada pra quem está
// usando o app.
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

// "2026-08-14T10:00:00Z" -> "14/08/2026 | 10:00", usado na tela de detalhes.
String formatarDataHora(String? iso) {
  final data = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (data == null) return '—';
  final dd = data.day.toString().padLeft(2, '0');
  final mm = data.month.toString().padLeft(2, '0');
  final hh = data.hour.toString().padLeft(2, '0');
  final min = data.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${data.year} | $hh:$min';
}

// O campo "ativo" do estabelecimento vem do banco como tinyint — a API
// devolve às vezes 1/0 (num), às vezes true/false (bool), dependendo do
// endpoint. Normaliza pros dois casos pra não quebrar o cast no Flutter Web.
bool? paraBool(dynamic valor) {
  if (valor == null) return null;
  if (valor is bool) return valor;
  if (valor is num) return valor != 0;
  return null;
}

// Mesmo formato usado no card de estabelecimento do painel admin no desktop
// (Dashboard.jsx/CardEstab): "Rua, Número - Bairro (Cidade/Estado)".
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
