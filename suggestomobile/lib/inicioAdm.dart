import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'detalhesSugestaoAdm.dart';

// Início do painel administrativo no mobile. Ainda não está ligado à API —
// os números abaixo são só pra dar forma à tela (ver PlanoController/AdminController
// no backend pra quando isso for integrado de verdade).
class InicioAdm extends StatefulWidget {
  const InicioAdm({super.key});

  @override
  State<InicioAdm> createState() => _InicioAdmState();
}

class _InicioAdmState extends State<InicioAdm> {
  int paginaAtual = 0;

  final String nomeEstabelecimento = "Cotil - Colégio Técnico";
  final int novasSugestoes = 24;
  final double engajamento = 18;

  final List<_ItemStatus> status = [
    _ItemStatus('Pendentes', 15, Icons.schedule, Cores.amarelo),
    _ItemStatus('Em análise', 9, Icons.search, Cores.azul),
    _ItemStatus('Implementados', 42, Icons.check_circle, Cores.verde),
    _ItemStatus('Recusados', 6, Icons.cancel, Cores.vermelho),
  ];

  final List<Map<String, dynamic>> sugestoesRecentes = [
    {
      'titulo': 'Melhorar a iluminação do pátio',
      'descricao':
          'A iluminação do pátio principal está muito fraca, principalmente durante o período noturno. '
              'Seria importante melhorar para garantir mais segurança e conforto para os alunos que ficam no período da noite.',
      'categoria': 'Estrutura',
      'status': 'pendente',
      'prioridade': 'alta',
      'tempo': 'há 2h',
      'autor': 'Manuela Nogueira',
      'data': '05/11/2024 | 14:30',
    },
    {
      'titulo': 'Adicionar mais opções vegetarianas',
      'descricao':
          'O cardápio do refeitório tem poucas opções sem carne. Ter mais alternativas vegetarianas ajudaria '
              'bastante quem segue esse tipo de dieta.',
      'categoria': 'Produtos e Serviços',
      'status': 'analise',
      'prioridade': 'media',
      'tempo': 'há 5h',
      'autor': 'Rafael Gonçalves',
      'data': '05/11/2024 | 09:10',
    },
    {
      'titulo': 'Melhorar atendimento da secretaria',
      'descricao':
          'O atendimento na secretaria costuma demorar bastante nos horários de pico. Um sistema de senhas '
              'ajudaria a organizar a fila.',
      'categoria': 'Atendimento',
      'status': 'implementado',
      'prioridade': 'media',
      'tempo': 'há 1d',
      'autor': 'Diogo Bernasconi',
      'data': '04/11/2024 | 11:45',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCabecalho(),
              const SizedBox(height: 20),
              _buildCartoesResumo(),
              const SizedBox(height: 24),
              _buildStatusSugestoes(),
              const SizedBox(height: 24),
              _buildSugestoesRecentes(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBarraNavegacao(),
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
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none, color: Colors.white70, size: 22),
              Positioned(
                top: 10,
                right: 11,
                child: _PontoNotificacao(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartoesResumo() {
    return Row(
      children: [
        Expanded(
          child: _cartaoResumo('$novasSugestoes', 'Novas Sugestões', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cartaoResumo(
            '+${engajamento.toStringAsFixed(0)}%',
            'Engajamento',
            Cores.verde,
          ),
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

  Widget _buildStatusSugestoes() {
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
          for (final item in status) _linhaStatus(item),
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
                pillStatus(s['status']),
                Text(
                  s['tempo'],
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
              s['titulo'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Categoria: ${s['categoria']}',
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

class _PontoNotificacao extends StatelessWidget {
  const _PontoNotificacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(color: Cores.roxo, shape: BoxShape.circle),
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
