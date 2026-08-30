// Quem está logado agora, guardado em memória — o app ainda não persiste
// login entre reinícios (nada de shared_preferences ainda). login.dart
// preenche isso depois de autenticar; as outras telas só leem.
class Sessao {
  static int? idUsuario;
  static String? nome;
  static String? email;
  static String? tipoUsuario;

  // Uma pessoa pode possuir um estabelecimento e ser só funcionária de outro
  // ao mesmo tempo agora — não existe mais um "dono efetivo" fixo por sessão
  // vindo do login. "Sou dona" é por estabelecimento (campo souDono, vindo da
  // API); quem mostra o estabelecimento específico ajusta isso depois de
  // buscá-lo (ver perfilAdm.dart).
  static bool souDonoDoEstabelecimentoAtual = false;

  static bool get logado => idUsuario != null;
  static bool get ehAdministrador => tipoUsuario == 'Administrador';

  static void definir({
    required int idUsuarioLogado,
    required String nomeLogado,
    required String emailLogado,
    required String tipoUsuarioLogado,
  }) {
    idUsuario = idUsuarioLogado;
    nome = nomeLogado;
    email = emailLogado;
    tipoUsuario = tipoUsuarioLogado;
  }

  static void sair() {
    idUsuario = null;
    nome = null;
    email = null;
    tipoUsuario = null;
    souDonoDoEstabelecimentoAtual = false;
  }
}
