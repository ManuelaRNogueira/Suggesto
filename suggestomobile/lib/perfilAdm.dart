import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cores.dart';
import 'sessao.dart';
import 'api.dart';
import 'formatacao.dart';

// Perfil do administrador/estabelecimento — endereço, contato, sobre e
// métricas vêm de GET /api/estabelecimentos/{id} (nota/avaliações incluídas
// via aplicarMediasDeAvaliacao no backend) + GET /api/admin/metricas
// (implementados, mesma fonte usada na tela Início do admin).
class PerfilAdm extends StatefulWidget {
  const PerfilAdm({super.key});

  @override
  State<PerfilAdm> createState() => _PerfilAdmState();
}

class _PerfilAdmState extends State<PerfilAdm> {
  int paginaAtual = 3;

  bool carregando = true;
  String? erro;

  Map<String, dynamic>? estabelecimento;
  int melhorias = 0;

  String? codigoEquipe;
  List<Map<String, dynamic>> solicitacoes = [];
  bool codigoCopiado = false;
  final Set<int> _solicitacoesProcessando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final idGerente = Sessao.idUsuario;
      final estabs = await buscarEstabelecimentosAdmin(idGerente: idGerente);
      if (estabs.isEmpty) {
        setState(() => erro = 'Nenhum estabelecimento cadastrado.');
        return;
      }
      final idEstabelecimento = (estabs.first['id'] as num).toInt();
      // "Sou dona" agora é por estabelecimento (campo souDono, vindo da API)
      // — uma pessoa pode ser dona de um e só funcionária de outro.
      Sessao.souDonoDoEstabelecimentoAtual =
          (estabs.first['souDono'] as bool?) ?? false;
      final resultados = await Future.wait([
        buscarEstabelecimento(idEstabelecimento),
        buscarMetricasAdmin(idGerente: idGerente),
      ]);

      List<Map<String, dynamic>> pendentes = [];
      if (Sessao.souDonoDoEstabelecimentoAtual && idGerente != null) {
        // Só o admin principal gerencia a equipe — o backend também confere
        // isso em aceitar/recusar, então evita a chamada extra pros demais.
        pendentes = (await buscarSolicitacoesAdmin(
          idGerente: idGerente,
        )).cast<Map<String, dynamic>>();
      }

      setState(() {
        estabelecimento = resultados[0] as Map<String, dynamic>;
        melhorias =
            ((resultados[1] as Map<String, dynamic>)['implementados'] as num?)
                ?.toInt() ??
            0;
        codigoEquipe = estabs.first['codigoAcesso'] as String?;
        solicitacoes = pendentes;
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> _copiarCodigo() async {
    final codigo = codigoEquipe;
    if (codigo == null) return;
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    setState(() => codigoCopiado = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => codigoCopiado = false);
    });
  }

  Future<void> _responderSolicitacao(int id, bool aceitar) async {
    final idGerente = Sessao.idUsuario;
    if (idGerente == null) return;
    setState(() => _solicitacoesProcessando.add(id));
    try {
      if (aceitar) {
        await aceitarSolicitacao(id, idGerente: idGerente);
      } else {
        await recusarSolicitacao(id, idGerente: idGerente);
      }
      if (!mounted) return;
      setState(
        () => solicitacoes.removeWhere((s) => (s['id'] as num).toInt() == id),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _solicitacoesProcessando.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(child: _corpo()),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  Widget _corpo() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: Cores.roxo));
    }
    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _carregar,
                child: const Text(
                  'Tentar de novo',
                  style: TextStyle(color: Cores.roxo, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final e = estabelecimento!;
    return RefreshIndicator(
      color: Cores.roxo,
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopoConfig(),
            const SizedBox(height: 12),
            _buildCabecalho(e),
            const SizedBox(height: 20),
            _buildCardContato(e),
            const SizedBox(height: 16),
            _buildCardSobre(e),
            const SizedBox(height: 16),
            _buildCardMetricas(),
            if (Sessao.souDonoDoEstabelecimentoAtual) ...[
              const SizedBox(height: 16),
              _buildCardCodigoEquipe(),
              const SizedBox(height: 16),
              _buildCardSolicitacoes(),
            ],
            const SizedBox(height: 16),
            _buildSairButton(),
          ],
        ),
      ),
    );
  }

  // Mesma lógica de confirmação e logout do Perfil do cliente
  // (perfilClie.dart) — só a tela de origem muda.
  Future<void> _confirmarSaida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Cores.fundo,
          title: const Text(
            'Sair da conta',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sair',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    Sessao.sair();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildSairButton() {
    return GestureDetector(
      onTap: _confirmarSaida,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sair da conta',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopoConfig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Cores.borda),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(Map<String, dynamic> e) {
    final nome = (e['nome'] as String?) ?? 'Estabelecimento';
    final categoria = (e['categoria'] as String?) ?? '';
    final nota = (e['mediaAvaliacoes'] as num?)?.toDouble();
    final fotoUrl = urlFotoEstabelecimento(e['fotoPath'] as String?);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: fotoUrl != null
              ? Image.network(
                  fotoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _logoPlaceholder(),
                )
              : _logoPlaceholder(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'PoppinsSemi',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (categoria.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  categoria,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (nota != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Cores.tag,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Cores.roxo.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Cores.amarelo,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nota.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'PoppinsSemi',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Editar perfil ainda não está pronto.',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Cores.roxoBotao,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Editar perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'PoppinsSemi',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.storefront, color: Colors.white38),
    );
  }

  Widget _buildCardContato(Map<String, dynamic> e) {
    final rua = (e['rua'] as String?) ?? '';
    final numero = (e['numero'] as String?) ?? '';
    final bairro = (e['bairro'] as String?) ?? '';
    final cidade = (e['cidade'] as String?) ?? '';
    final estado = (e['estado'] as String?) ?? '';
    final partesEndereco = <String>[
      if (rua.isNotEmpty) (numero.isNotEmpty ? '$rua, $numero' : rua),
      if (bairro.isNotEmpty) bairro,
      if (cidade.isNotEmpty) (estado.isNotEmpty ? '$cidade - $estado' : cidade),
    ];
    final endereco = partesEndereco.isNotEmpty
        ? partesEndereco.join(' - ')
        : 'Endereço não informado';

    final telefone = (e['telefone'] as String?)?.isNotEmpty == true
        ? e['telefone'] as String
        : 'Não informado';
    final email = (Sessao.email?.isNotEmpty == true)
        ? Sessao.email!
        : 'Não informado';
    final horario = (e['horarioFuncionamento'] as String?)?.isNotEmpty == true
        ? e['horarioFuncionamento'] as String
        : 'Não informado';

    return _card(
      titulo: null,
      filhos: [
        _linhaContato(Icons.location_on_outlined, endereco),
        _linhaContato(Icons.phone_outlined, telefone),
        _linhaContato(Icons.email_outlined, email),
        _linhaContato(Icons.schedule_outlined, horario, ultima: true),
      ],
    );
  }

  Widget _linhaContato(IconData icone, String texto, {bool ultima = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Cores.roxo, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSobre(Map<String, dynamic> e) {
    final sobre = (e['sobre'] as String?)?.isNotEmpty == true
        ? e['sobre'] as String
        : 'Nenhuma descrição cadastrada ainda.';

    return _card(
      titulo: 'Sobre',
      filhos: [
        Text(
          sobre,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCardMetricas() {
    return _card(
      titulo: null,
      filhos: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Cores.verde, size: 22),
            const SizedBox(width: 12),
            Text(
              '$melhorias',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'PoppinsBold',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'melhorias',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardCodigoEquipe() {
    final codigo = codigoEquipe;
    return _card(
      titulo: 'Código da equipe',
      filhos: [
        Text(
          'Compartilhe com quem vai administrar esse estabelecimento junto com você.',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontFamily: 'Poppins',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Cores.campo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  codigo ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PoppinsSemi',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: codigo == null ? null : _copiarCodigo,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: codigoCopiado ? Cores.verdeFundo : Cores.roxoBotao,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  codigoCopiado ? Icons.check : Icons.copy,
                  color: codigoCopiado ? Cores.verde : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardSolicitacoes() {
    return _card(
      titulo: 'Solicitações de entrada',
      filhos: [
        if (solicitacoes.isEmpty)
          const Text(
            'Nenhuma solicitação pendente.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          )
        else
          for (final s in solicitacoes) _linhaSolicitacao(s),
      ],
    );
  }

  Widget _linhaSolicitacao(Map<String, dynamic> s) {
    final id = (s['id'] as num).toInt();
    final processando = _solicitacoesProcessando.contains(id);
    final nome = (s['nomeUsuario'] as String?) ?? 'Usuário';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.campo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (s['emailUsuario'] as String?) ?? '',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatarData(s['dataSolicitacao'] as String?),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: processando
                      ? null
                      : () => _responderSolicitacao(id, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Recusar',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'PoppinsSemi',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: processando
                      ? null
                      : () => _responderSolicitacao(id, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Cores.verdeFundo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: processando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Cores.verde,
                          ),
                        )
                      : const Text(
                          'Aceitar',
                          style: TextStyle(
                            color: Cores.verde,
                            fontFamily: 'PoppinsSemi',
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required String? titulo, required List<Widget> filhos}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null) ...[
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...filhos,
        ],
      ),
    );
  }

  Widget _buildBarraNavegacao() {
    final abas = [
      _Aba('Início', Icons.home_filled, '/inicioAdm'),
      _Aba('Sugestões', Icons.forum, '/sugestoesAdm'),
      _Aba('Locais', Icons.storefront, '/estabelecimentosAdm'),
      _Aba('Perfil', Icons.person, '/perfilAdm'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Cores.fundo,
        border: Border(top: BorderSide(color: Cores.cartao, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < abas.length; i++) _itemNavegacao(abas[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNavegacao(_Aba aba, int indice) {
    final ativo = paginaAtual == indice;
    return GestureDetector(
      onTap: () {
        setState(() => paginaAtual = indice);
        if (aba.rota != '/perfilAdm') Navigator.pushNamed(context, aba.rota);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(aba.icone, color: ativo ? Colors.white : Colors.white54),
          const SizedBox(height: 4),
          Text(
            aba.rotulo,
            style: TextStyle(
              color: ativo ? Colors.white : Colors.white54,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _Aba {
  final String rotulo;
  final IconData icone;
  final String rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
