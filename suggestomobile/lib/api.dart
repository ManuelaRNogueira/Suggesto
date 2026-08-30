import 'dart:convert';
import 'package:http/http.dart' as http;

// Camada de acesso à API — porte do que já existe em
// "Suggesto - Web/Web/js/config.js" e nas outras plataformas (Suggesto_DesktopReact/renderer/src/api/admin.js).
// Sem "location.hostname" pra detectar ambiente como no navegador, então o
// padrão aponta direto pro backend hospedado; pra rodar contra um backend
// local use: flutter run --dart-define=API_BASE=http://10.0.2.2:8080/api
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://suggesto-api.onrender.com/api',
);

// A base sem "/api" — é onde ficam as fotos (ver EstabelecimentoController /
// UsuarioController: as imagens sobem pra "/uploads/...", fora do prefixo da API).
String get apiOrigin => apiBase.replaceFirst('/api', '');

class ApiException implements Exception {
  final String mensagem;
  ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

// ── Base HTTP — os métodos abaixo só existem pra não repetir o mesmo
//    try/catch e leitura de erro em cada chamada ──────────────────────────

Future<http.Response> _enviar(String metodo, String caminho, {Map<String, dynamic>? corpo}) async {
  try {
    final uri = Uri.parse('$apiBase$caminho');
    switch (metodo) {
      case 'GET':
        return await http.get(uri).timeout(const Duration(seconds: 15));
      case 'POST':
        return await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(corpo ?? {}))
            .timeout(const Duration(seconds: 15));
      case 'PATCH':
        return await http
            .patch(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(corpo ?? {}))
            .timeout(const Duration(seconds: 15));
      case 'DELETE':
        return await http.delete(uri).timeout(const Duration(seconds: 15));
      default:
        throw ArgumentError('Método não suportado: $metodo');
    }
  } catch (e) {
    if (e is ArgumentError) rethrow;
    throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet.');
  }
}

// Mensagem de erro pode vir em "message" (a maioria dos endpoints) ou em
// "erro" (só o POST /api/avaliacoes) — checa os dois.
String _mensagemDeErro(http.Response resposta) {
  try {
    final dados = jsonDecode(resposta.body);
    if (dados is Map) {
      if (dados['message'] != null) return dados['message'].toString();
      if (dados['erro'] != null) return dados['erro'].toString();
    }
  } catch (_) {}
  return 'Erro ${resposta.statusCode}.';
}

Future<Map<String, dynamic>> _mapa(String metodo, String caminho, {Map<String, dynamic>? corpo}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  if (resposta.body.isEmpty) return {};
  final decodificado = jsonDecode(resposta.body);
  return decodificado is Map<String, dynamic> ? decodificado : {};
}

Future<List<dynamic>> _lista(String metodo, String caminho, {Map<String, dynamic>? corpo}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  if (resposta.body.isEmpty) return [];
  final decodificado = jsonDecode(resposta.body);
  return decodificado is List ? decodificado : [];
}

Future<void> _vazio(String metodo, String caminho, {Map<String, dynamic>? corpo}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
}

// ── Autenticação ──────────────────────────────────────────────────────────

// POST /api/login (AuthController.realizarAutenticacao) — retorna
// { success, message, nome, idUsuario, tipoUsuario }.
Future<Map<String, dynamic>> login({required String email, required String senha}) {
  return _mapa('POST', '/login', corpo: {'email': email, 'senha': senha});
}

// POST /api/cadastro (AuthController.cadastrarUsuario) — cria só a conta;
// plano e estabelecimento são cadastrados depois, em outro fluxo.
Future<Map<String, dynamic>> cadastrar({
  required String nome,
  required String username,
  required String email,
  required String senha,
  required String tipoUsuario,
  String? telefone,
  String? cep,
  String? cidade,
  String? estado,
}) {
  return _mapa('POST', '/cadastro', corpo: {
    'nome': nome,
    'username': username,
    'email': email,
    'senha': senha,
    'tipoUsuario': tipoUsuario,
    if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
    if (cep != null && cep.isNotEmpty) 'cep': cep,
    if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
    if (estado != null && estado.isNotEmpty) 'estado': estado,
  });
}

// POST /api/estabelecimentos/entrar (EstabelecimentoController) — não entra
// direto: cria uma SolicitacaoEquipe que o administrador principal aprova
// depois (ver Solicitações no painel admin do desktop).
Future<Map<String, dynamic>> entrarNaEquipe({required int usuarioId, required String codigo}) {
  return _mapa('POST', '/estabelecimentos/entrar', corpo: {'usuarioId': usuarioId, 'codigo': codigo});
}

// GET /api/estabelecimentos/solicitacoes?idGerente= — pedidos de entrada
// pendentes pros estabelecimentos desse gerente (só o principal deveria
// chamar isso — o backend confere o mesmo em aceitar/recusar).
Future<List<dynamic>> buscarSolicitacoesAdmin({required int idGerente}) {
  return _lista('GET', '/estabelecimentos/solicitacoes?idGerente=$idGerente');
}

// POST /api/estabelecimentos/solicitacoes/{id}/aceitar — vincula o usuário
// ao estabelecimento e apaga a solicitação. 403 se idGerente não for dono.
Future<Map<String, dynamic>> aceitarSolicitacao(int id, {required int idGerente}) {
  return _mapa('POST', '/estabelecimentos/solicitacoes/$id/aceitar', corpo: {'idGerente': idGerente});
}

// POST /api/estabelecimentos/solicitacoes/{id}/recusar — só apaga a solicitação.
Future<Map<String, dynamic>> recusarSolicitacao(int id, {required int idGerente}) {
  return _mapa('POST', '/estabelecimentos/solicitacoes/$id/recusar', corpo: {'idGerente': idGerente});
}

// ── Painel do administrador ─────────────────────────────────────────────

// GET /api/admin/metricas — números pra tela Início e Estatísticas do admin.
Future<Map<String, dynamic>> buscarMetricasAdmin({int? idGerente, int meses = 6}) {
  final params = <String>['meses=$meses'];
  if (idGerente != null) params.add('idGerente=$idGerente');
  return _mapa('GET', '/admin/metricas?${params.join('&')}');
}

// GET /api/admin/sugestoes — lista de avaliações do(s) estabelecimento(s) do gerente.
Future<List<dynamic>> buscarSugestoesAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/sugestoes$query');
}

// GET /api/admin/estabelecimentos — estabelecimentos do gerente (inclui inativos).
Future<List<dynamic>> buscarEstabelecimentosAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/estabelecimentos$query');
}

// PATCH /api/avaliacoes/{id}/status — usado na tela de Detalhes da sugestão.
Future<Map<String, dynamic>> atualizarStatusAvaliacao(int id, String status) {
  return _mapa('PATCH', '/avaliacoes/$id/status', corpo: {'status': status});
}

// PATCH /api/avaliacoes/{id}/resposta — admin responde a uma sugestão.
Future<Map<String, dynamic>> responderAvaliacao(int id, {required int idAdmin, required String resposta}) {
  return _mapa('PATCH', '/avaliacoes/$id/resposta', corpo: {'idAdmin': idAdmin, 'resposta': resposta});
}

// ── Estabelecimentos (navegação do cliente) ─────────────────────────────

// GET /api/estabelecimentos — todos os ativos, pra tela Início/Buscar.
Future<List<dynamic>> buscarEstabelecimentos() {
  return _lista('GET', '/estabelecimentos');
}

// GET /api/estabelecimentos/{id} — detalhe de um local.
Future<Map<String, dynamic>> buscarEstabelecimento(int id) {
  return _mapa('GET', '/estabelecimentos/$id');
}

// GET /api/estabelecimentos/recomendados?idUsuario= — mesma cidade do usuário.
Future<Map<String, dynamic>> buscarRecomendados(int idUsuario) {
  return _mapa('GET', '/estabelecimentos/recomendados?idUsuario=$idUsuario');
}

// ── Avaliações ("sugestões" do lado cliente) ────────────────────────────

// GET /api/avaliacoes/estabelecimento/{id} — avaliações recebidas por um local.
Future<List<dynamic>> buscarAvaliacoesEstabelecimento(int idEstabelecimento) {
  return _lista('GET', '/avaliacoes/estabelecimento/$idEstabelecimento');
}

// GET /api/avaliacoes/usuario/{id} — "Minhas Sugestões".
Future<List<dynamic>> buscarAvaliacoesUsuario(int idUsuario) {
  return _lista('GET', '/avaliacoes/usuario/$idUsuario');
}

// GET /api/categorias — devolve todas as categorias de sugestão que existem.
// Quem decide quais fazem sentido pra cada ramo de estabelecimento é o
// config central em categoriasPorRamo.dart (ver filtrarCategoriasPorRamo),
// não o backend — o parâmetro abaixo é aceito mas ignorado pela API, mantido
// só porque não atrapalha e documenta a intenção de quem chama.
Future<List<dynamic>> buscarCategorias(String? tipoEstabelecimento) {
  final query = (tipoEstabelecimento != null && tipoEstabelecimento.isNotEmpty)
      ? '?tipoEstabelecimento=${Uri.encodeQueryComponent(tipoEstabelecimento)}'
      : '';
  return _lista('GET', '/categorias$query');
}

// POST /api/avaliacoes — cria uma sugestão/crítica/elogio. idCategoria vem
// da lista já filtrada por filtrarCategoriasPorRamo (ver sugerir.dart).
Future<void> criarAvaliacao({
  required int idUsuario,
  required int idEstabelecimento,
  required int idCategoria,
  required int nota,
  required String comentario,
  String tipo = 'sugestao',
}) {
  return _vazio('POST', '/avaliacoes', corpo: {
    'idUsuario': idUsuario,
    'idEstabelecimento': idEstabelecimento,
    'idCategoria': idCategoria,
    'nota': nota,
    'comentario': comentario,
    'tipo': tipo,
  });
}

// DELETE /api/avaliacoes/{id}?idUsuario= — só enquanto estiver pendente.
Future<void> excluirAvaliacao(int id, int idUsuario) {
  return _vazio('DELETE', '/avaliacoes/$id?idUsuario=$idUsuario');
}

// ── Perfil ────────────────────────────────────────────────────────────────

// GET /api/usuarios/{id}
Future<Map<String, dynamic>> buscarUsuario(int id) {
  return _mapa('GET', '/usuarios/$id');
}

// GET /api/usuarios/{id}/conquistas
Future<List<dynamic>> buscarConquistas(int id) {
  return _lista('GET', '/usuarios/$id/conquistas');
}

// PUT /api/usuarios/{id} — só aceita multipart/form-data, mesmo sem foto
// (é assim que o UsuarioController espera, igual ao site em perfilCli.js).
Future<Map<String, dynamic>> atualizarUsuario(int id, {String? nome, String? telefone, String? cidade}) async {
  final requisicao = http.MultipartRequest('PUT', Uri.parse('$apiBase/usuarios/$id'));
  if (nome != null) requisicao.fields['nome'] = nome;
  if (telefone != null) requisicao.fields['telefone'] = telefone;
  if (cidade != null) requisicao.fields['cidade'] = cidade;

  http.StreamedResponse enviada;
  try {
    enviada = await requisicao.send().timeout(const Duration(seconds: 15));
  } catch (_) {
    throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet.');
  }
  final resposta = await http.Response.fromStream(enviada);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  final decodificado = jsonDecode(resposta.body);
  return decodificado is Map<String, dynamic> ? decodificado : {};
}

// ── Locais salvos (favoritos) ───────────────────────────────────────────

// GET /api/locais-salvos/usuario/{id}
Future<List<dynamic>> buscarLocaisSalvos(int usuarioId) {
  return _lista('GET', '/locais-salvos/usuario/$usuarioId');
}

// POST /api/locais-salvos — idempotente, não dá erro se já estava salvo.
Future<void> salvarLocal({required int usuarioId, required int estabelecimentoId}) {
  return _vazio('POST', '/locais-salvos', corpo: {'usuarioId': usuarioId, 'estabelecimentoId': estabelecimentoId});
}

// DELETE /api/locais-salvos/{usuarioId}/{estabelecimentoId}
Future<void> removerLocalSalvo({required int usuarioId, required int estabelecimentoId}) {
  return _vazio('DELETE', '/locais-salvos/$usuarioId/$estabelecimentoId');
}

// ── Recompensas e resgates ──────────────────────────────────────────────

// GET /api/recompensas — vitrine de recompensas de todos os estabelecimentos.
Future<List<dynamic>> buscarRecompensas() {
  return _lista('GET', '/recompensas');
}

// GET /api/resgates/usuario/{id} — histórico de resgates do usuário.
Future<List<dynamic>> buscarResgates(int idUsuario) {
  return _lista('GET', '/resgates/usuario/$idUsuario');
}

// POST /api/resgates — o backend confere e debita os pontos; aqui só manda o pedido.
Future<Map<String, dynamic>> resgatar({required int usuarioId, required int recompensaId}) {
  return _mapa('POST', '/resgates', corpo: {'usuarioId': usuarioId, 'recompensaId': recompensaId});
}

// ── CEP (ViaCEP) ─────────────────────────────────────────────────────────
// Serviço externo, não é a API do Suggesto — usado só pra autocompletar
// cidade/estado no cadastro (mesma chamada que "Suggesto - Web/Web/js/cadastro.js").

Future<Map<String, dynamic>> buscarCep(String cep) async {
  final digitos = cep.replaceAll(RegExp(r'\D'), '');
  http.Response resposta;
  try {
    resposta = await http
        .get(Uri.parse('https://viacep.com.br/ws/$digitos/json/'))
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    throw ApiException('Não foi possível consultar o CEP agora.');
  }
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException('Não foi possível consultar o CEP agora.');
  }
  final dados = jsonDecode(resposta.body);
  if (dados is! Map<String, dynamic> || dados['erro'] == true) {
    throw ApiException('CEP não encontrado.');
  }
  return dados;
}

// ── Geocodificação (Nominatim / OpenStreetMap) ──────────────────────────
// Sem API paga: Estabelecimento não guarda lat/lng (ver infoLocal.dart), então
// convertemos o endereço em coordenadas via Nominatim — gratuito, sem chave.
// Falha (endereço não encontrado, sem internet, etc.) retorna null em vez de
// lançar exceção: geocodificação é "melhor esforço", a tela cai pro texto do
// endereço se isso não funcionar.
//
// O bairro cadastrado no banco nem sempre bate com o nome que o OSM usa pra
// aquele trecho — incluir na busca faz a Nominatim não achar nada mesmo com
// rua/cidade corretos. Por isso não entra na consulta: tenta rua+número
// primeiro, e se não achar, tenta só rua (às vezes o número não está
// mapeado, mas a rua está).
Future<Map<String, double>?> buscarCoordenadasEndereco({
  required String rua,
  String? numero,
  required String cidade,
  required String estado,
}) async {
  if (rua.isEmpty || cidade.isEmpty) return null;

  final tentativas = <String>[
    if (numero != null && numero.isNotEmpty) '$rua, $numero, $cidade, $estado',
    '$rua, $cidade, $estado',
  ];

  for (final consulta in tentativas) {
    final coords = await _consultarNominatim(consulta);
    if (coords != null) return coords;
  }
  return null;
}

Future<Map<String, double>?> _consultarNominatim(String consulta) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': consulta,
    'format': 'json',
    'limit': '1',
    'countrycodes': 'br',
  });
  http.Response resposta;
  try {
    resposta = await http
        .get(uri, headers: {'User-Agent': 'SuggestoApp/1.0 (suggesto.app)'})
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    return null;
  }
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) return null;

  final decodificado = jsonDecode(resposta.body);
  if (decodificado is! List || decodificado.isEmpty) return null;

  final item = decodificado.first;
  final lat = double.tryParse(item['lat']?.toString() ?? '');
  final lng = double.tryParse(item['lon']?.toString() ?? '');
  if (lat == null || lng == null) return null;
  return {'lat': lat, 'lng': lng};
}

// ── Fotos ─────────────────────────────────────────────────────────────────

// Estabelecimento.fotoPath / Recompensa.fotoPath vêm como nome de arquivo cru
// (ou já uma URL completa, se foi pro Cloudinary).
String? urlFotoEstabelecimento(String? fotoPath) {
  if (fotoPath == null || fotoPath.isEmpty) return null;
  if (fotoPath.startsWith('http')) return fotoPath;
  final limpo = fotoPath.replaceFirst(RegExp(r'^/?uploads/'), '');
  return '$apiOrigin/uploads/$limpo';
}

// Usuario.fotoUrl (de GET /api/usuarios/{id}) já vem com o prefixo "/uploads/"
// aplicado pelo backend, ou vazio.
String? urlFotoUsuario(String? fotoUrl) {
  if (fotoUrl == null || fotoUrl.isEmpty) return null;
  if (fotoUrl.startsWith('http')) return fotoUrl;
  return '$apiOrigin$fotoUrl';
}
