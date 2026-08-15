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

// "2026-08-14T10:00:00" -> "há 2h" / "há 3d" / "14/08/2026".
String formatarData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final data = DateTime.tryParse(iso);
  if (data == null) return '—';
  final horas = DateTime.now().difference(data).inHours;
  if (horas < 1) return 'agora';
  if (horas < 24) return 'há ${horas}h';
  final dias = horas ~/ 24;
  if (dias < 7) return 'há ${dias}d';
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

// "2026-08-14T10:00:00" -> "14/08/2026 | 10:00", usado na tela de detalhes.
String formatarDataHora(String? iso) {
  final data = iso == null ? null : DateTime.tryParse(iso);
  if (data == null) return '—';
  final dd = data.day.toString().padLeft(2, '0');
  final mm = data.month.toString().padLeft(2, '0');
  final hh = data.hour.toString().padLeft(2, '0');
  final min = data.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${data.year} | $hh:$min';
}
