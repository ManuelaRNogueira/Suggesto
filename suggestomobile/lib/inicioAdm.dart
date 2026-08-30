import 'package:flutter/material.dart';
import 'cores.dart';
import 'sessao.dart';
import 'api.dart';
import 'detalhesSugestaoAdm.dart';
import 'cartaoSugestaoAdm.dart';

// Início do painel administrativo — busca em GET /api/admin/metricas e
// GET /api/admin/estabelecimentos (ver AdminController no backend).
class InicioAdm extends StatefulWidget {
  const InicioAdm({super.key});

  @override
  State<InicioAdm> createState() => _InicioAdmState();
}

class _InicioAdmState extends State<InicioAdm> {
  int paginaAtual = 0;

  bool carregando = true;
  String? erro;

  Map<String, dynamic>? metricas;
  String nomeEstabelecimento = 'Painel administrativo';
  List<Map<String, dynamic>> sugestoesRecentes = [];

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
      final resultados = await Future.wait([
        buscarMetricasAdmin(idGerente: idGerente),
        buscarEstabelecimentosAdmin(idGerente: idGerente),
      ]);
      final m = resultados[0] as Map<String, dynamic>;
      final estabs = resultados[1] as List<dynamic>;

      setState(() {
        metricas = m;
        sugestoesRecentes = ((m['sugestoesRecentes'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
        if (estabs.length == 1) {
          nomeEstabelecimento =
              estabs.first['nome']?.toString() ?? 'Painel administrativo';
        } else if (estabs.length > 1) {
          nomeEstabelecimento = '${estabs.length} estabelecimentos';
        } else {
          nomeEstabelecimento = 'Nenhum estabelecimento cadastrado';
        }
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

    final m = metricas!;
    return RefreshIndicator(
      color: Cores.roxo,
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecalho(),
            const SizedBox(height: 20),
            _buildCartaoNovasSemana(m),
            const SizedBox(height: 12),
            _buildStatusCards(m),
            const SizedBox(height: 24),
            _buildSugestoesRecentes(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Início',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontFamily: 'PoppinsBold',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          nomeEstabelecimento,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildCartaoNovasSemana(Map<String, dynamic> m) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(m['novasSemana'] as num?)?.toInt() ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'PoppinsBold',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Novas na semana',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Três cards por status — mesmo modelo do painel admin no desktop
  // (.ini-kpi em Inicio.jsx/Inicio.css): barrinha colorida no topo, rótulo,
  // número grande na cor do status e "% do total" embaixo.
  Widget _buildStatusCards(Map<String, dynamic> m) {
    final total = (m['totalSugestoes'] as num?)?.toInt() ?? 0;
    final pendentes = (m['pendentes'] as num?)?.toInt() ?? 0;
    final implementados = (m['implementados'] as num?)?.toInt() ?? 0;
    final recusados = (m['recusados'] as num?)?.toInt() ?? 0;
    double pct(int qtd) => total > 0 ? (qtd / total) * 100 : 0;

    return Row(
      children: [
        Expanded(
          child: _cartaoStatus(
            'Pendente',
            pendentes,
            pct(pendentes),
            Cores.amarelo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _cartaoStatus(
            'Implementado',
            implementados,
            pct(implementados),
            Cores.verde,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _cartaoStatus(
            'Recusado',
            recusados,
            pct(recusados),
            Cores.vermelho,
          ),
        ),
      ],
    );
  }

  Widget _cartaoStatus(
    String rotulo,
    int quantidade,
    double percentual,
    Color cor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            rotulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$quantidade',
            style: TextStyle(
              color: cor,
              fontSize: 22,
              fontFamily: 'PoppinsBold',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentual.toStringAsFixed(1)}% do total',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugestoesRecentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões Recentes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'PoppinsSemi',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (sugestoesRecentes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nenhuma sugestão ainda.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          )
        else
          for (final s in sugestoesRecentes)
            cartaoSugestaoAdm(
              sugestao: s,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalhesSugestaoAdm(sugestao: s),
                  ),
                );
                setState(() {});
              },
            ),
      ],
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
        if (aba.rota == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${aba.rotulo} ainda não está pronto.',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          );
          return;
        }
        if (aba.rota != '/inicioAdm') Navigator.pushNamed(context, aba.rota!);
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
  final String? rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
