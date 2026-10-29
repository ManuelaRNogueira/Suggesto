//dados de quem está logado (só em memória: fechou o app, perde o login)
//o login.dart preenche, as outras telas só leem
class Sessao {
  static int? idUsuario;
  static String? nome;
  static String? email;
  static String? tipoUsuario;

  //se é dono do estabelecimento aberto agora (muda por estabelecimento,
  //a pessoa pode ser dona de um e só funcionária de outro)
  static bool souDonoDoEstabelecimentoAtual = false;

  static bool get logado => idUsuario != null;
  static bool get ehAdministrador => tipoUsuario == 'Administrador';

  //salva os dados depois do login
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

  //logout: limpa tudo
  static void sair() {
    idUsuario = null;
    nome = null;
    email = null;
    tipoUsuario = null;
    souDonoDoEstabelecimentoAtual = false;
  }
}
