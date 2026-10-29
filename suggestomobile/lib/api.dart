//comunica com o servidor
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'formatacao.dart';
import 'sessao.dart';

//endereço da API
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://suggesto-api.onrender.com/api',
);

//endereço do servidor sem a API (onde fica as fotos)
String get apiOrigin => apiBase.replaceFirst('/api', '');

//endereço do site (onde fica o QR de check-in)
const String siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://suggestosite.onrender.com',
);

//monta o link que vai dentro do QR de check-in (o mesmo que o desktop imprime)
String urlCheckin(int idEstabelecimento, String tokenCheckin) {
  return '$siteUrl/fazerSugestao.html?id=$idEstabelecimento&t=${Uri.encodeQueryComponent(tokenCheckin)}';
}

//erro com uma mensagem pronta pra mostrar na tela
class ApiException implements Exception {
  final String mensagem;
  ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

//função central, todos os pedidos passam por ela
//faz o GET/POST/PATCH/DELETE e, se não tiver internet, lança erro amigável
Future<http.Response> _enviar(
  String metodo,
  String caminho, {
  Map<String, dynamic>? corpo,
}) async {
  try {
    final uri = Uri.parse('$apiBase$caminho');
    switch (metodo) {
      case 'GET':
        return await http.get(uri).timeout(const Duration(seconds: 15));
      case 'POST':
        return await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(corpo ?? {}),
            )
            .timeout(const Duration(seconds: 15));
      case 'PATCH':
        return await http
            .patch(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(corpo ?? {}),
            )
            .timeout(const Duration(seconds: 15));
      case 'DELETE':
        return await http.delete(uri).timeout(const Duration(seconds: 15));
      default:
        throw ArgumentError('Método não suportado: $metodo');
    }
  } catch (e) {
    if (e is ArgumentError) rethrow;
    throw ApiException(
      'Não foi possível conectar ao servidor. Verifique sua internet.',
    );
  }
}

//pega a mensagem de erro da resposta (vem em "message" ou "erro")
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

//faz o pedido e devolve a resposta como um objeto (Map)
Future<Map<String, dynamic>> _mapa(
  String metodo,
  String caminho, {
  Map<String, dynamic>? corpo,
}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  if (resposta.body.isEmpty) return {};
  final decodificado = jsonDecode(resposta.body);
  return decodificado is Map<String, dynamic> ? decodificado : {};
}

//faz o pedido e devolve a resposta como uma lista
Future<List<dynamic>> _lista(
  String metodo,
  String caminho, {
  Map<String, dynamic>? corpo,
}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  if (resposta.body.isEmpty) return [];
  final decodificado = jsonDecode(resposta.body);
  return decodificado is List ? decodificado : [];
}

//faz o pedido e só confere se deu certo (não precisa da resposta)
Future<void> _vazio(
  String metodo,
  String caminho, {
  Map<String, dynamic>? corpo,
}) async {
  final resposta = await _enviar(metodo, caminho, corpo: corpo);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
}

// ── Conta e equipe ────────────────────────────────────────────────────────

//entra na conta: manda email e senha e recebe os dados do usuário pra sessão
Future<Map<String, dynamic>> login({
  required String email,
  required String senha,
}) {
  return _mapa('POST', '/login', corpo: {'email': email, 'senha': senha});
}

//pede o link de redefinir senha por email
//a resposta é sempre a mesma, exista o email ou não (pra não revelar contas)
Future<Map<String, dynamic>> esqueciSenha(String email) {
  return _mapa('POST', '/senha/esqueci', corpo: {'email': email});
}

//cria a conta do usuário (campos opcionais vazios não são enviados)
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
  return _mapa(
    'POST',
    '/cadastro',
    corpo: {
      'nome': nome,
      'username': username,
      'email': email,
      'senha': senha,
      'tipoUsuario': tipoUsuario,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (cep != null && cep.isNotEmpty) 'cep': cep,
      if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
      if (estado != null && estado.isNotEmpty) 'estado': estado,
    },
  );
}

//pede pra entrar na equipe de um estabelecimento usando o código de acesso
//não entra na hora: o dono precisa aprovar o pedido
Future<Map<String, dynamic>> entrarNaEquipe({
  required int usuarioId,
  required String codigo,
}) {
  return _mapa(
    'POST',
    '/estabelecimentos/entrar',
    corpo: {'usuarioId': usuarioId, 'codigo': codigo},
  );
}

//lista os pedidos de entrada na equipe esperando o dono aprovar
Future<List<dynamic>> buscarSolicitacoesAdmin({required int idGerente}) {
  return _lista('GET', '/estabelecimentos/solicitacoes?idGerente=$idGerente');
}

//aprova o pedido: o usuário passa a fazer parte da equipe
Future<Map<String, dynamic>> aceitarSolicitacao(
  int id, {
  required int idGerente,
}) {
  return _mapa(
    'POST',
    '/estabelecimentos/solicitacoes/$id/aceitar',
    corpo: {'idGerente': idGerente},
  );
}

//recusa o pedido: ele é apagado e ninguém entra na equipe
Future<Map<String, dynamic>> recusarSolicitacao(
  int id, {
  required int idGerente,
}) {
  return _mapa(
    'POST',
    '/estabelecimentos/solicitacoes/$id/recusar',
    corpo: {'idGerente': idGerente},
  );
}

// ── Painel do administrador ───────────────────────────────────────────────

//números do painel (gráficos dos últimos meses)
//filtra por gerente e/ou estabelecimento só se forem passados
Future<Map<String, dynamic>> buscarMetricasAdmin({
  int? idGerente,
  int meses = 6,
  int? idEstabelecimento,
}) {
  final params = <String>['meses=$meses'];
  if (idGerente != null) params.add('idGerente=$idGerente');
  if (idEstabelecimento != null)
    params.add('idEstabelecimento=$idEstabelecimento');
  return _mapa('GET', '/admin/metricas?${params.join('&')}');
}

//sugestões recebidas pelos estabelecimentos do gerente
Future<List<dynamic>> buscarSugestoesAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/sugestoes$query');
}

//estabelecimentos que o gerente administra (inclusive os inativos)
Future<List<dynamic>> buscarEstabelecimentosAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/estabelecimentos$query');
}

//muda o status de uma sugestão (ex: pendente → implementado)
//pra recusar precisa de um motivo com pelo menos 10 caracteres
Future<Map<String, dynamic>> atualizarStatusAvaliacao(
  int id,
  String status, {
  String? motivo,
}) {
  return _mapa(
    'PATCH',
    '/avaliacoes/$id/status',
    corpo: {'status': status, 'idAdmin': Sessao.idUsuario, 'motivo': motivo},
  );
}

//o admin responde a sugestão do cliente
Future<Map<String, dynamic>> responderAvaliacao(
  int id, {
  required int idAdmin,
  required String resposta,
}) {
  return _mapa(
    'PATCH',
    '/avaliacoes/$id/resposta',
    corpo: {'idAdmin': idAdmin, 'resposta': resposta},
  );
}

// ── Estabelecimentos ──────────────────────────────────────────────────────

//todos os estabelecimentos ativos (telas Início e Buscar)
Future<List<dynamic>> buscarEstabelecimentos() {
  return _lista('GET', '/estabelecimentos');
}

//detalhe de um estabelecimento
//se idSolicitante for o dono, também vem o código de acesso e o token do QR
Future<Map<String, dynamic>> buscarEstabelecimento(
  int id, {
  int? idSolicitante,
}) {
  final query = idSolicitante != null ? '?idSolicitante=$idSolicitante' : '';
  return _mapa('GET', '/estabelecimentos/$id$query');
}

//gera um token novo pro QR de check-in (só o dono)
//os QRs antigos param de funcionar
Future<Map<String, dynamic>> gerarNovoTokenCheckin(
  int idEstabelecimento, {
  required int idSolicitante,
}) {
  return _mapa(
    'POST',
    '/estabelecimentos/$idEstabelecimento/token-checkin?idSolicitante=$idSolicitante',
  );
}

//nota de transparência do estabelecimento (0 a 100)
//leva em conta quanto ele responde, recusa e a rapidez das respostas
Future<Map<String, dynamic>> buscarTransparencia(int id) {
  return _mapa('GET', '/estabelecimentos/$id/reputacao');
}

//estabelecimentos do gerente com todos os dados juntos
//pega a lista básica (ativo, código, se é dono) e completa com o detalhe de
//cada um (foto, endereço). Usada na lista de estabelecimentos e no Perfil
Future<List<Map<String, dynamic>>> buscarEstabelecimentosVinculados({
  int? idGerente,
}) async {
  final basicos = await buscarEstabelecimentosAdmin(idGerente: idGerente);
  final detalhes = await Future.wait(
    basicos.map(
      (b) => buscarEstabelecimento(
        (b['id'] as num).toInt(),
        idSolicitante: idGerente,
      ),
    ),
  );
  return [
    for (var i = 0; i < basicos.length; i++)
      {
        ...detalhes[i],
        'id': (basicos[i] as Map<String, dynamic>)['id'],
        'ativo': paraBool((basicos[i] as Map<String, dynamic>)['ativo']),
        'codigoAcesso': (basicos[i] as Map<String, dynamic>)['codigoAcesso'],
        'souDono': (basicos[i] as Map<String, dynamic>)['souDono'],
        'tokenCheckin': detalhes[i]['tokenCheckin'],
      },
  ];
}

//estabelecimentos recomendados pela cidade do usuário
Future<Map<String, dynamic>> buscarRecomendados(int idUsuario) {
  return _mapa('GET', '/estabelecimentos/recomendados?idUsuario=$idUsuario');
}

// ── Sugestões (avaliações) ────────────────────────────────────────────────

//sugestões que um estabelecimento recebeu
Future<List<dynamic>> buscarAvaliacoesEstabelecimento(int idEstabelecimento) {
  return _lista('GET', '/avaliacoes/estabelecimento/$idEstabelecimento');
}

//sugestões que o usuário enviou (tela Minhas Sugestões)
Future<List<dynamic>> buscarAvaliacoesUsuario(int idUsuario) {
  return _lista('GET', '/avaliacoes/usuario/$idUsuario');
}

//todas as categorias de sugestão (atendimento, comida...)
//o servidor ignora tipoEstabelecimento; quem filtra é o categoriasPorRamo.dart
Future<List<dynamic>> buscarCategorias(String? tipoEstabelecimento) {
  final query = (tipoEstabelecimento != null && tipoEstabelecimento.isNotEmpty)
      ? '?tipoEstabelecimento=${Uri.encodeQueryComponent(tipoEstabelecimento)}'
      : '';
  return _lista('GET', '/categorias$query');
}

//envia uma sugestão nova pra um estabelecimento
//idVisita é o check-in feito antes (prova que o cliente esteve lá)
Future<void> criarAvaliacao({
  required int idUsuario,
  required int idEstabelecimento,
  required int idCategoria,
  required int nota,
  required String comentario,
  String tipo = 'sugestao',
  int? idVisita,
}) {
  return _vazio(
    'POST',
    '/avaliacoes',
    corpo: {
      'idUsuario': idUsuario,
      'idEstabelecimento': idEstabelecimento,
      'idCategoria': idCategoria,
      'nota': nota,
      'comentario': comentario,
      'tipo': tipo,
      'idVisita': idVisita,
    },
  );
}

//confirma que o cliente está no local, pelo token do QR ou pelo GPS
//devolve {idVisita, expiraEm}; se já tiver uma visita aberta, devolve ela
Future<Map<String, dynamic>> fazerCheckin({
  required int idUsuario,
  required int idEstabelecimento,
  String? token,
  double? lat,
  double? lng,
}) {
  return _mapa(
    'POST',
    '/estabelecimentos/$idEstabelecimento/checkin',
    corpo: {'idUsuario': idUsuario, 'token': token, 'lat': lat, 'lng': lng},
  );
}

//apaga uma sugestão do usuário (só se ainda estiver pendente)
Future<void> excluirAvaliacao(int id, int idUsuario) {
  return _vazio('DELETE', '/avaliacoes/$id?idUsuario=$idUsuario');
}

// ── Perfil ────────────────────────────────────────────────────────────────

//dados do usuário pro Perfil
//email e telefone só vêm se for o perfil de quem está logado
Future<Map<String, dynamic>> buscarUsuario(int id) {
  return _mapa('GET', '/usuarios/$id?idSolicitante=${Sessao.idUsuario}');
}

//conquistas (badges) que o usuário já desbloqueou
Future<List<dynamic>> buscarConquistas(int id) {
  return _lista('GET', '/usuarios/$id/conquistas');
}

//nota de confiabilidade do usuário (0 a 100)
//das sugestões com visita confirmada, quantas foram aceitas
Future<Map<String, dynamic>> buscarReputacao(int id) {
  return _mapa('GET', '/usuarios/$id/reputacao');
}

//edita o perfil (nome, telefone, cidade e foto)
//usa multipart porque a foto é um arquivo, não dá pra mandar como JSON
Future<Map<String, dynamic>> atualizarUsuario(
  int id, {
  String? nome,
  String? telefone,
  String? cidade,
  Uint8List? fotoBytes,
}) async {
  final requisicao = http.MultipartRequest(
    'PUT',
    Uri.parse('$apiBase/usuarios/$id?idSolicitante=${Sessao.idUsuario}'),
  );
  if (nome != null) requisicao.fields['nome'] = nome;
  if (telefone != null) requisicao.fields['telefone'] = telefone;
  if (cidade != null) requisicao.fields['cidade'] = cidade;
  if (fotoBytes != null) {
    requisicao.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        fotoBytes,
        filename: 'foto_perfil.png',
        contentType: MediaType('image', 'png'),
      ),
    );
  }

  http.StreamedResponse enviada;
  try {
    enviada = await requisicao.send().timeout(const Duration(seconds: 15));
  } catch (_) {
    throw ApiException(
      'Não foi possível conectar ao servidor. Verifique sua internet.',
    );
  }
  final resposta = await http.Response.fromStream(enviada);
  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw ApiException(_mensagemDeErro(resposta));
  }
  final decodificado = jsonDecode(resposta.body);
  return decodificado is Map<String, dynamic> ? decodificado : {};
}

// ── Locais salvos (favoritos) ─────────────────────────────────────────────

//estabelecimentos que o usuário favoritou
Future<List<dynamic>> buscarLocaisSalvos(int usuarioId) {
  return _lista('GET', '/locais-salvos/usuario/$usuarioId');
}

//favorita um estabelecimento (se já estiver salvo, não duplica)
Future<void> salvarLocal({
  required int usuarioId,
  required int estabelecimentoId,
}) {
  return _vazio(
    'POST',
    '/locais-salvos',
    corpo: {'usuarioId': usuarioId, 'estabelecimentoId': estabelecimentoId},
  );
}

//tira o estabelecimento dos favoritos
Future<void> removerLocalSalvo({
  required int usuarioId,
  required int estabelecimentoId,
}) {
  return _vazio('DELETE', '/locais-salvos/$usuarioId/$estabelecimentoId');
}

// ── Recompensas ───────────────────────────────────────────────────────────

//todas as recompensas disponíveis (vitrine)
Future<List<dynamic>> buscarRecompensas() {
  return _lista('GET', '/recompensas');
}

//recompensas que o usuário já resgatou
Future<List<dynamic>> buscarResgates(int idUsuario) {
  return _lista('GET', '/resgates/usuario/$idUsuario');
}

//troca pontos por uma recompensa
//o servidor confere se tem pontos suficientes e desconta
Future<Map<String, dynamic>> resgatar({
  required int usuarioId,
  required int recompensaId,
}) {
  return _mapa(
    'POST',
    '/resgates',
    corpo: {'usuarioId': usuarioId, 'recompensaId': recompensaId},
  );
}

// ── Serviços de fora ──────────────────────────────────────────────────────

//busca cidade e estado pelo CEP (ViaCEP), usado no cadastro
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

//transforma o endereço em latitude/longitude pro mapa (Nominatim, grátis)
//tenta rua+número, depois só a rua; o bairro fica de fora porque atrapalha
//se não achar, devolve null e a tela mostra só o endereço em texto
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

//faz uma busca no Nominatim e devolve {lat, lng} do primeiro resultado
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

//monta o link da foto de estabelecimento/recompensa
//se já for link (Cloudinary) usa direto, senão junta com o endereço do servidor
String? urlFotoEstabelecimento(String? fotoPath) {
  if (fotoPath == null || fotoPath.isEmpty) return null;
  if (fotoPath.startsWith('http')) return fotoPath;
  final limpo = fotoPath.replaceFirst(RegExp(r'^/?uploads/'), '');
  return '$apiOrigin/uploads/$limpo';
}

//monta o link da foto do usuário (já vem com "/uploads/...")
String? urlFotoUsuario(String? fotoUrl) {
  if (fotoUrl == null || fotoUrl.isEmpty) return null;
  if (fotoUrl.startsWith('http')) return fotoUrl;
  return '$apiOrigin$fotoUrl';
}
