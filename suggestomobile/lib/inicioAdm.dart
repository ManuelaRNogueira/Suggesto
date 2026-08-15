import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'formatacao.dart';
import 'sessao.dart';
import 'api.dart';
import 'detalhesSugestaoAdm.dart';

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
      final idGerente = Sessao.idGerenteEfetivo;
      final resultados = await Future.wait([
        buscarMetricasAdmin(idGerente: idGerente),
        buscarEstabelecimentosAdmin(idGerente: idGerente),
      ]);
      final m = resultados[0] as Map<String, dynamic>;
      final estabs = resultados[1] as List<dynamic>;

      setState(() {
        metricas = m;
        sugestoesRecentes = ((m['sugestoesRecentes'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
        if (estabs.length == 1) {
          nomeEstabelecimento = estabs.first['nome']?.toString() ?? 'Painel administrativo';
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
              Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              TextButton(onPressed: _carregar, child: const Text('Tentar de novo', style: TextStyle(color: Cores.roxo, fontFamily: 'Poppins'))),
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
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecalho(),
            const SizedBox(height: 20),
            _buildCartoesResumo(m),
            const SizedBox(height: 24),
            _buildStatusSugestoes(m),
            const SizedBox(height: 24),
            _buildSugestoesRecentes(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Cores.cartao,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Cores.borda),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.white70, size: 22),
        ),
      ],
    );
  }

  Widget _buildCartoesResumo(Map<String, dynamic> m) {
    final total = (m['totalSugestoes'] as num?)?.toInt() ?? 0;
    final implementados = (m['implementados'] as num?)?.toInt() ?? 0;
    final aproveitamento = total > 0 ? ((implementados / total) * 100).round() : 0;

    return Row(
      children: [
        Expanded(
          child: _cartaoResumo('${(m['novasSemana'] as num?)?.toInt() ?? 0}', 'Novas na semana', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cartaoResumo('$aproveitamento%', 'Aproveitamento', Cores.verde),
        ),
      ],
    );
  }

  Widget _cartaoResumo(String valor, String rotulo, Color corValor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              color: corValor,
              fontSize: 24,
              fontFamily: 'PoppinsBold',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSugestoes(Map<String, dynamic> m) {
    final itens = [
      _ItemStatus('Pendentes', (m['pendentes'] as num?)?.toInt() ?? 0, Icons.schedule, Cores.amarelo),
      _ItemStatus('Implementados', (m['implementados'] as num?)?.toInt() ?? 0, Icons.check_circle, Cores.verde),
      _ItemStatus('Recusados', (m['recusados'] as num?)?.toInt() ?? 0, Icons.cancel, Cores.vermelho),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Status das Sugestões',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final item in itens) _linhaStatus(item),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _linhaStatus(_ItemStatus item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(item.icone, color: item.cor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.rotulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            '${item.quantidade}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
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
              style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'Poppins'),
            ),
          )
        else
          for (final s in sugestoesRecentes) _cartaoSugestao(s),
      ],
    );
  }

  Widget _cartaoSugestao(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalhesSugestaoAdm(sugestao: s)),
        );
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Cores.cartao,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Cores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                pillStatus((s['statusUi'] as String?) ?? 'pendente'),
                Text(
                  formatarData(s['dataAvaliacao'] as String?),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tituloSugestao(s['comentario'] as String?),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Categoria: ${s['categoria'] ?? 'Sem categoria'}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontFamily: 'Poppins',
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
      _Aba('Estatísticas', Icons.bar_chart, null),
      _Aba('Perfil', Icons.person, null),
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

class _ItemStatus {
  final String rotulo;
  final int quantidade;
  final IconData icone;
  final Color cor;
  _ItemStatus(this.rotulo, this.quantidade, this.icone, this.cor);
}

class _Aba {
  final String rotulo;
  final IconData icone;
  final String? rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
