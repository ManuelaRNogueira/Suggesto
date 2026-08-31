import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'formatacao.dart';

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

// Essa função é a "telefonista" central do app: toda conversa com o
// servidor passa por aqui, que decide o tipo de pedido (buscar, salvar,
// apagar) e já trata erro de um jeito parecido, pra não repetir esse
// código em cada tela.

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

// ── Autenticação ──────────────────────────────────────────────────────────
// Funções de entrar e criar conta: mandam email/senha (ou os dados de
// cadastro) pro servidor conferir/gravar. Validação pesada fica por conta
// do back-end — aqui é só empacotar os dados e repassar.

// Login: servidor confere email e senha e devolve os dados básicos do
// usuário (nome, id, tipo de conta) pra guardar na sessão do app.
Future<Map<String, dynamic>> login({
  required String email,
  required String senha,
}) {
  return _mapa('POST', '/login', corpo: {'email': email, 'senha': senha});
}

// Cadastro: cria só a conta mesmo (nome, email, senha, endereço...). Se o
// usuário for dono de estabelecimento, o plano e o próprio estabelecimento
// entram depois, em outra etapa — aqui é só "criar o usuário".
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

// Quem tem o código de acesso de um estabelecimento pode pedir pra entrar
// na equipe dele, mas não entra na hora: isso cria um pedido pendente
// (SolicitacaoEquipe) que o dono do estabelecimento precisa aprovar depois
// — é como pedir pra entrar num grupo fechado e esperar alguém liberar.
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

// Lista os pedidos de entrada ainda pendentes pros estabelecimentos desse
// gerente — a "caixa de pedidos" que aparece pro dono aprovar ou recusar.
Future<List<dynamic>> buscarSolicitacoesAdmin({required int idGerente}) {
  return _lista('GET', '/estabelecimentos/solicitacoes?idGerente=$idGerente');
}

// Aceita o pedido: vincula o usuário ao estabelecimento de vez e apaga a
// solicitação. Só o dono pode aceitar — o servidor confere isso de novo do
// próprio lado, não confia só no que o app manda.
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

// Recusa o pedido: só apaga a solicitação, ninguém é vinculado.
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

// ── Painel do administrador ─────────────────────────────────────────────
// Funções que alimentam as telas de admin: números gerais (métricas), a
// lista de sugestões recebidas, quais estabelecimentos esse gerente
// administra, e as ações de responder ou mudar o status de uma sugestão.

// Monta a query aos poucos porque idGerente e idEstabelecimento são
// opcionais — só entram na URL se vierem preenchidos.
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

// Lista as sugestões recebidas pelos estabelecimentos desse gerente.
Future<List<dynamic>> buscarSugestoesAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/sugestoes$query');
}

// Estabelecimentos que esse gerente administra — inclui os inativos, ao
// contrário da busca pública que o cliente vê.
Future<List<dynamic>> buscarEstabelecimentosAdmin({int? idGerente}) {
  final query = idGerente != null ? '?idGerente=$idGerente' : '';
  return _lista('GET', '/admin/estabelecimentos$query');
}

// Muda o status de uma sugestão (ex: pendente → respondida), na tela de
// Detalhes da sugestão.
Future<Map<String, dynamic>> atualizarStatusAvaliacao(int id, String status) {
  return _mapa('PATCH', '/avaliacoes/$id/status', corpo: {'status': status});
}

// Admin escreve uma resposta pra sugestão que o cliente mandou.
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

// ── Estabelecimentos (navegação do cliente) ─────────────────────────────
// Funções que o cliente usa pra descobrir e ver estabelecimentos: lista
// geral, detalhe de um específico, e recomendados pra cidade dele.

// Todos os estabelecimentos ativos, pra tela Início/Buscar.
Future<List<dynamic>> buscarEstabelecimentos() {
  return _lista('GET', '/estabelecimentos');
}

// Detalhe completo de um estabelecimento específico.
Future<Map<String, dynamic>> buscarEstabelecimento(int id) {
  return _mapa('GET', '/estabelecimentos/$id');
}

// Essa função existe pra não repetir o mesmo "quebra-cabeça" em duas telas:
// busca a lista básica dos estabelecimentos do gerente (se está ativo, o
// código de acesso, se ele é o dono) e depois busca o detalhe completo
// (foto, endereço) de cada um, juntando tudo num objeto só. Usada tanto na
// lista de Estabelecimentos do admin quanto no resumo de "Estabelecimentos
// vinculados" do Perfil.
Future<List<Map<String, dynamic>>> buscarEstabelecimentosVinculados({
  int? idGerente,
}) async {
  final basicos = await buscarEstabelecimentosAdmin(idGerente: idGerente);
  final detalhes = await Future.wait(
    basicos.map((b) => buscarEstabelecimento((b['id'] as num).toInt())),
  );
  return [
    for (var i = 0; i < basicos.length; i++)
      {
        ...detalhes[i],
        'id': (basicos[i] as Map<String, dynamic>)['id'],
        'ativo': paraBool((basicos[i] as Map<String, dynamic>)['ativo']),
        'codigoAcesso': (basicos[i] as Map<String, dynamic>)['codigoAcesso'],
        'souDono': (basicos[i] as Map<String, dynamic>)['souDono'],
      },
  ];
}

// Recomendados pro usuário — o servidor decide com base na cidade dele.
Future<Map<String, dynamic>> buscarRecomendados(int idUsuario) {
  return _mapa('GET', '/estabelecimentos/recomendados?idUsuario=$idUsuario');
}

// ── Avaliações ("sugestões" do lado cliente) ────────────────────────────
// Funções de ver, criar e apagar avaliações — o que na tela do cliente
// aparece como "sugestão", crítica ou elogio pra um estabelecimento.

// Avaliações que um estabelecimento recebeu (visão de quem administra).
Future<List<dynamic>> buscarAvaliacoesEstabelecimento(int idEstabelecimento) {
  return _lista('GET', '/avaliacoes/estabelecimento/$idEstabelecimento');
}

// Avaliações que o próprio usuário enviou — tela "Minhas Sugestões".
Future<List<dynamic>> buscarAvaliacoesUsuario(int idUsuario) {
  return _lista('GET', '/avaliacoes/usuario/$idUsuario');
}

// Traz todas as categorias de sugestão que existem no sistema (ex:
// "atendimento", "comida"...). Quem decide quais fazem sentido pra cada
// tipo de estabelecimento é o próprio app, em categoriasPorRamo.dart — o
// parâmetro tipoEstabelecimento aqui é só decorativo, o servidor não filtra
// nada com ele.
Future<List<dynamic>> buscarCategorias(String? tipoEstabelecimento) {
  final query = (tipoEstabelecimento != null && tipoEstabelecimento.isNotEmpty)
      ? '?tipoEstabelecimento=${Uri.encodeQueryComponent(tipoEstabelecimento)}'
      : '';
  return _lista('GET', '/categorias$query');
}

// Cria uma sugestão nova. idCategoria já vem escolhido pelo usuário entre
// as opções filtradas na tela (ver sugerir.dart).
Future<void> criarAvaliacao({
  required int idUsuario,
  required int idEstabelecimento,
  required int idCategoria,
  required int nota,
  required String comentario,
  String tipo = 'sugestao',
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
    },
  );
}

// Só dá pra apagar enquanto a sugestão ainda estiver pendente de resposta.
Future<void> excluirAvaliacao(int id, int idUsuario) {
  return _vazio('DELETE', '/avaliacoes/$id?idUsuario=$idUsuario');
}

// ── Perfil ────────────────────────────────────────────────────────────────
// Dados da tela de Perfil: informações básicas do usuário, conquistas
// (badges) e a edição do perfil (nome, telefone, cidade, foto).

// Dados do usuário pra tela de Perfil.
Future<Map<String, dynamic>> buscarUsuario(int id) {
  return _mapa('GET', '/usuarios/$id');
}

// Conquistas (badges) que o usuário já desbloqueou.
Future<List<dynamic>> buscarConquistas(int id) {
  return _lista('GET', '/usuarios/$id/conquistas');
}

// Diferente de mandar só texto, aqui a foto vai "dentro de um envelope"
// especial (multipart), porque imagem não cabe dentro de uma mensagem de
// texto comum como o resto dos dados do perfil.
Future<Map<String, dynamic>> atualizarUsuario(
  int id, {
  String? nome,
  String? telefone,
  String? cidade,
  Uint8List? fotoBytes,
}) async {
  final requisicao = http.MultipartRequest(
    'PUT',
    Uri.parse('$apiBase/usuarios/$id'),
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

// ── Locais salvos (favoritos) ───────────────────────────────────────────
// A "estrelinha" de favoritar um estabelecimento: salvar, listar e
// remover da lista de locais salvos do usuário.

// Locais que o usuário salvou como favoritos.
Future<List<dynamic>> buscarLocaisSalvos(int usuarioId) {
  return _lista('GET', '/locais-salvos/usuario/$usuarioId');
}

// Salva o local como favorito. Se o usuário já tinha salvo antes, não dá
// erro — só não duplica, é seguro chamar de novo sem se preocupar.
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

// Tira o local dos favoritos.
Future<void> removerLocalSalvo({
  required int usuarioId,
  required int estabelecimentoId,
}) {
  return _vazio('DELETE', '/locais-salvos/$usuarioId/$estabelecimentoId');
}

// ── Recompensas e resgates ──────────────────────────────────────────────
// Vitrine de recompensas disponíveis, histórico de resgates do usuário, e
// o pedido de resgate em si (trocar pontos por uma recompensa).

// Recompensas disponíveis de todos os estabelecimentos, pra vitrine.
Future<List<dynamic>> buscarRecompensas() {
  return _lista('GET', '/recompensas');
}

// Histórico de resgates que o usuário já fez.
Future<List<dynamic>> buscarResgates(int idUsuario) {
  return _lista('GET', '/resgates/usuario/$idUsuario');
}

// Pede pra trocar pontos por uma recompensa. Quem confere se o usuário tem
// pontos suficientes e desconta é o servidor — o app só faz o pedido e
// espera a resposta.
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

// ── CEP (ViaCEP) ─────────────────────────────────────────────────────────
// Isso aqui não é a nossa API — é um serviço de fora (ViaCEP) que a gente
// usa emprestado só pra preencher cidade/estado sozinho quando o usuário
// digita o CEP no cadastro (mesma ideia da versão web, em
// "Suggesto - Web/Web/js/cadastro.js").

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
// O banco só guarda o nome do arquivo da foto (ou às vezes um link já
// pronto, se foi pro Cloudinary) — essas funções colam o endereço certo na
// frente pra virar uma URL que dá pra exibir na tela.

// Foto de estabelecimento/recompensa: pode vir só com o nome do arquivo, ou
// já pronta como link do Cloudinary — aqui a gente detecta os dois casos e
// monta a URL certa.
String? urlFotoEstabelecimento(String? fotoPath) {
  if (fotoPath == null || fotoPath.isEmpty) return null;
  if (fotoPath.startsWith('http')) return fotoPath;
  final limpo = fotoPath.replaceFirst(RegExp(r'^/?uploads/'), '');
  return '$apiOrigin/uploads/$limpo';
}

// Foto de usuário já vem do servidor com o "/uploads/..." colado na
// frente — só falta grudar o endereço base.
String? urlFotoUsuario(String? fotoUrl) {
  if (fotoUrl == null || fotoUrl.isEmpty) return null;
  if (fotoUrl.startsWith('http')) return fotoUrl;
  return '$apiOrigin$fotoUrl';
}
