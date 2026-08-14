import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';

// Detalhe de uma sugestão, com os botões pra trocar o status — versão mobile
// da mesma ação que existe na tela de Sugestões do desktop
// (Suggesto_DesktopReact/renderer/src/pages/admin/Sugestoes.jsx, atualizarStatusSugestao).
// `sugestao` é o mesmo Map da lista (passado por referência): mudar o status
// aqui já reflete na lista quando voltar, sem precisar de um estado global.
class DetalhesSugestaoAdm extends StatefulWidget {
  final Map<String, dynamic> sugestao;

  const DetalhesSugestaoAdm({super.key, required this.sugestao});

  @override
  State<DetalhesSugestaoAdm> createState() => _DetalhesSugestaoAdmState();
}

class _DetalhesSugestaoAdmState extends State<DetalhesSugestaoAdm> {
  int paginaAtual = 1;

  static const _statusDisponiveis = ['analise', 'recusado', 'implementado', 'pendente'];

  void _mudarStatus(String novoStatus) {
    setState(() => widget.sugestao['status'] = novoStatus);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sugestao;
    final statusAtual = s['status'] as String;
    final outrosStatus = _statusDisponiveis.where((st) => st != statusAtual).toList();

    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  const Text(
                    'Detalhes da Sugestão',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'PoppinsSemi',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _seloStatus(statusAtual),
                    const SizedBox(height: 20),
                    _cartaoDetalhe(s),
                    const SizedBox(height: 24),
                    _botoesStatus(outrosStatus),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  Widget _seloStatus(String status) {
    final estilo = estiloDoStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: estilo.corFundo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: estilo.cor, size: 15),
          const SizedBox(width: 6),
          Text(
            descricaoDoStatus(status),
            style: TextStyle(color: estilo.cor, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _cartaoDetalhe(Map<String, dynamic> s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s['titulo'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'PoppinsSemi',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (s['prioridade'] == 'alta') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0x29FF5252), borderRadius: BorderRadius.circular(6)),
                  child: const Text(
                    'Alta prioridade',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s['descricao'],
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins', height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Categoria: ${s['categoria']}',
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          const Divider(color: Cores.borda, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Cores.tag,
                child: Text(
                  _iniciais(s['autor']),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'PoppinsSemi'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s['autor'],
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                ),
              ),
              Text(
                s['data'],
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    final primeiras = partes.take(2).map((p) => p.isNotEmpty ? p[0].toUpperCase() : '');
    return primeiras.join();
  }

  Widget _botoesStatus(List<String> statusList) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [for (final st in statusList) _botaoStatus(st)],
    );
  }

  Widget _botaoStatus(String status) {
    final estilo = estiloDoStatus(status);
    return OutlinedButton.icon(
      onPressed: () => _mudarStatus(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: estilo.cor,
        side: BorderSide(color: estilo.cor.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(_iconeStatus(status), size: 16),
      label: Text(
        estilo.rotulo,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'analise':
        return Icons.search;
      case 'implementado':
        return Icons.check_circle_outline;
      case 'recusado':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
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
        Navigator.pushNamed(context, aba.rota!);
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
