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

class ApiException implements Exception {
  final String mensagem;
  ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

Future<Map<String, dynamic>> _postJson(String caminho, Map<String, dynamic> corpo) async {
  http.Response resposta;
  try {
    resposta = await http
        .post(
          Uri.parse('$apiBase$caminho'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(corpo),
        )
        .timeout(const Duration(seconds: 15));
  } catch (_) {
    throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet.');
  }

  Map<String, dynamic> dados;
  try {
    final decodificado = jsonDecode(resposta.body);
    dados = decodificado is Map<String, dynamic> ? decodificado : {'message': resposta.body};
  } catch (_) {
    dados = {'message': resposta.body};
  }

  if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
    return dados;
  }
  throw ApiException(dados['message']?.toString() ?? 'Erro ${resposta.statusCode}.');
}

// POST /api/login (AuthController.realizarAutenticacao) — retorna
// { success, message, nome, idUsuario, tipoUsuario, idGerenteEfetivo }.
Future<Map<String, dynamic>> login({required String email, required String senha}) {
  return _postJson('/login', {'email': email, 'senha': senha});
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
  return _postJson('/cadastro', {
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
  return _postJson('/estabelecimentos/entrar', {'usuarioId': usuarioId, 'codigo': codigo});
}
