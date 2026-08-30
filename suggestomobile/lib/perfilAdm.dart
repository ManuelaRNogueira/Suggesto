import 'package:flutter/material.dart';
import 'cores.dart';
import 'sessao.dart';
import 'api.dart';
import 'cartoesStatusAdm.dart';
import 'detalhesEstabelecimentoAdm.dart';

// Perfil pessoal do administrador — mesma estrutura do Perfil do mobile
// cliente (perfilClie.dart: foto, nome, e-mail, menu, sair), mas com dados
// do próprio usuário logado (GET /api/usuarios/{id}) em vez de um
// estabelecimento. Código da equipe e solicitações de entrada continuam na
// tela de detalhes de cada local (ver detalhesEstabelecimentoAdm.dart), já
// que um admin pode ter vários — aqui entra só a visão geral (métricas
// somadas de todos os estabelecimentos, GET /api/admin/metricas sem filtro
// de idEstabelecimento, mesma fonte da tela Início) e a lista de
// estabelecimentos vinculados à conta.
class PerfilAdm extends StatefulWidget {
  const PerfilAdm({super.key});

  @override
  State<PerfilAdm> createState() => _PerfilAdmState();
}

class _PerfilAdmState extends State<PerfilAdm> {
  int paginaAtual = 3;

  bool carregando = true;
  String? erro;
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? metricasGerais;
  List<Map<String, dynamic>> estabelecimentosVinculados = [];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.info_outline, 'label': 'Sobre Nós', 'route': '/sobrenos'},
    {
      'icon': Icons.emoji_objects_outlined,
      'label': 'O Suggesto',
      'route': '/suggesto',
    },
  ];

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
      final idUsuario = Sessao.idUsuario;
      if (idUsuario == null) {
        setState(() => erro = 'Sessão inválida. Faça login novamente.');
        return;
      }
      final resultados = await Future.wait([
        buscarUsuario(idUsuario),
        buscarMetricasAdmin(idGerente: idUsuario),
        buscarEstabelecimentosVinculados(idGerente: idUsuario),
      ]);
      setState(() {
        usuario = resultados[0] as Map<String, dynamic>;
        metricasGerais = resultados[1] as Map<String, dynamic>;
        estabelecimentosVinculados =
            resultados[2] as List<Map<String, dynamic>>;
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
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

    final u = usuario!;
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
            _buildCabecalho(u),
            const SizedBox(height: 20),
            _buildCardContato(u),
            const SizedBox(height: 24),
            _buildVisaoGeral(),
            const SizedBox(height: 24),
            _buildEstabelecimentosVinculados(),
            const SizedBox(height: 16),
            _buildMenuList(),
            const SizedBox(height: 16),
            _buildSairButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopoConfig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
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
      ],
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  Widget _buildCabecalho(Map<String, dynamic> u) {
    final nome = (u['nome'] as String?)?.trim();
    final email = (u['email'] as String?) ?? '';
    final fotoUrl = urlFotoUsuario(u['fotoUrl'] as String?);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Cores.roxo, width: 2.5),
          ),
          child: ClipOval(
            child: fotoUrl != null
                ? Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _iniciaisPlaceholder(nome ?? ''),
                  )
                : _iniciaisPlaceholder(nome ?? ''),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (nome != null && nome.isNotEmpty) ? nome : 'Administrador',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'PoppinsSemi',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Cores.tag,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Cores.roxo.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Cores.roxo,
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Administrador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'PoppinsSemi',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iniciaisPlaceholder(String nome) {
    return Container(
      color: Cores.cartao,
      alignment: Alignment.center,
      child: Text(
        _iniciais(nome),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 22,
          fontFamily: 'PoppinsBold',
        ),
      ),
    );
  }

  Widget _buildCardContato(Map<String, dynamic> u) {
    final telefone = (u['telefone'] as String?)?.trim();
    final cidade = (u['cidade'] as String?)?.trim();
    final estado = (u['estado'] as String?)?.trim();
    final localizacao = [
      if (cidade != null && cidade.isNotEmpty) cidade,
      if (estado != null && estado.isNotEmpty) estado,
    ].join(' - ');
    final plano = (u['nomePlano'] as String?)?.trim();

    final itens = <MapEntry<IconData, String>>[
      MapEntry(
        Icons.phone_outlined,
        telefone != null && telefone.isNotEmpty ? telefone : 'Não informado',
      ),
      if (localizacao.isNotEmpty)
        MapEntry(Icons.location_on_outlined, localizacao),
      if (plano != null && plano.isNotEmpty)
        MapEntry(Icons.workspace_premium_outlined, 'Plano $plano'),
    ];

    return _card(
      titulo: null,
      filhos: [
        for (var i = 0; i < itens.length; i++)
          _linhaContato(
            itens[i].key,
            itens[i].value,
            ultima: i == itens.length - 1,
          ),
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

  // Resumo geral da atuação do admin — soma de todos os estabelecimentos
  // vinculados a ele (mesma fonte da tela Início, só que sem filtrar por
  // idEstabelecimento), não de um local específico.
  Widget _buildVisaoGeral() {
    final m = metricasGerais;
    final total = (m?['totalSugestoes'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visão geral',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'PoppinsSemi',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Sugestões recebidas em todos os seus estabelecimentos.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Cores.cartao,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Cores.borda),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'PoppinsBold',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sugestões recebidas',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        cartoesStatusAdm(
          total: total,
          pendentes: (m?['pendentes'] as num?)?.toInt() ?? 0,
          implementados: (m?['implementados'] as num?)?.toInt() ?? 0,
          recusados: (m?['recusados'] as num?)?.toInt() ?? 0,
        ),
      ],
    );
  }

  // Versão simples do card "Estabelecimentos vinculados" do perfil do
  // desktop (Perfil.jsx): só a contagem e o nome de cada local — sem foto,
  // categoria ou endereço. Tocar no nome ainda abre a tela de detalhes já
  // existente no mobile ADM.
  Widget _buildEstabelecimentosVinculados() {
    final total = estabelecimentosVinculados.length;

    return _card(
      titulo: null,
      filhos: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estabelecimentos vinculados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Cores.tag,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  color: Cores.roxo,
                  fontSize: 12,
                  fontFamily: 'PoppinsSemi',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (estabelecimentosVinculados.isEmpty)
          const Text(
            'Nenhum estabelecimento vinculado.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          )
        else
          for (var i = 0; i < estabelecimentosVinculados.length; i++)
            _linhaEstabelecimentoVinculado(
              estabelecimentosVinculados[i],
              ultima: i == estabelecimentosVinculados.length - 1,
            ),
      ],
    );
  }

  Widget _linhaEstabelecimentoVinculado(
    Map<String, dynamic> e, {
    bool ultima = false,
  }) {
    final nome = (e['nome'] as String?) ?? 'Estabelecimento';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalhesEstabelecimentoAdm(estabelecimento: e),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: ultima ? 0 : 12),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: Cores.roxo, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return Container(
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Cores.borda, width: 1),
      ),
      child: Column(
        children: List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          final isLast = index == _menuItems.length - 1;
          return Column(
            children: [
              _buildMenuItem(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                onTap: () =>
                    Navigator.pushNamed(context, item['route'] as String),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
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
