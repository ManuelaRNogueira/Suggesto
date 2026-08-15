// Quem está logado agora, guardado em memória — o app ainda não persiste
// login entre reinícios (nada de shared_preferences ainda). login.dart
// preenche isso depois de autenticar; as outras telas só leem.
class Sessao {
  static int? idUsuario;
  static String? nome;
  static String? email;
  static String? tipoUsuario;
  static int? idGerenteEfetivo;

  static bool get logado => idUsuario != null;
  static bool get ehAdministrador => tipoUsuario == 'Administrador';
  static bool get ehPrincipal => logado && idUsuario == idGerenteEfetivo;

  static void definir({
    required int idUsuarioLogado,
    required String nomeLogado,
    required String emailLogado,
    required String tipoUsuarioLogado,
    int? idGerenteEfetivoLogado,
  }) {
    idUsuario = idUsuarioLogado;
    nome = nomeLogado;
    email = emailLogado;
    tipoUsuario = tipoUsuarioLogado;
    idGerenteEfetivo = idGerenteEfetivoLogado ?? idUsuarioLogado;
  }

  static void sair() {
    idUsuario = null;
    nome = null;
    email = null;
    tipoUsuario = null;
    idGerenteEfetivo = null;
  }
}
