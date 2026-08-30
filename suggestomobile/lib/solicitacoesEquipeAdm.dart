import 'package:flutter/material.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'sessao.dart';
import 'api.dart';

// Card "Solicitações de entrada" de um estabelecimento específico — mesma
// lógica que já existia em perfilAdm.dart (aceitar/recusar por
// GET/POST /api/estabelecimentos/solicitacoes), só que agora reaproveitada
// aqui e filtrada pelo estabelecimento sendo visto, já que o admin pode ter
// vários. A API não filtra por estabelecimento (só por idGerente), então o
// filtro é feito aqui a partir do campo estabelecimentoId que ela já devolve.
class SolicitacoesEquipeAdm extends StatefulWidget {
  final int idEstabelecimento;
  const SolicitacoesEquipeAdm({super.key, required this.idEstabelecimento});

  @override
  State<SolicitacoesEquipeAdm> createState() => _SolicitacoesEquipeAdmState();
}

class _SolicitacoesEquipeAdmState extends State<SolicitacoesEquipeAdm> {
  bool carregando = true;
  List<Map<String, dynamic>> solicitacoes = [];
  final Set<int> _processando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final idGerente = Sessao.idUsuario;
    if (idGerente == null) {
      setState(() => carregando = false);
      return;
    }
    setState(() => carregando = true);
    try {
      final todas = await buscarSolicitacoesAdmin(idGerente: idGerente);
      if (!mounted) return;
      setState(() {
        solicitacoes = todas
            .cast<Map<String, dynamic>>()
            .where(
              (s) =>
                  (s['estabelecimentoId'] as num?)?.toInt() ==
                  widget.idEstabelecimento,
            )
            .toList();
      });
    } on ApiException {
      // Sem solicitações não impede ver o resto da tela.
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> _responder(int id, bool aceitar) async {
    final idGerente = Sessao.idUsuario;
    if (idGerente == null) return;
    setState(() => _processando.add(id));
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
      if (mounted) setState(() => _processando.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Solicitações de entrada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Cores.roxo,
                  ),
                ),
              ),
            )
          else if (solicitacoes.isEmpty)
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
      ),
    );
  }

  Widget _linhaSolicitacao(Map<String, dynamic> s) {
    final id = (s['id'] as num).toInt();
    final processando = _processando.contains(id);
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
                  onPressed: processando ? null : () => _responder(id, false),
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
                  onPressed: processando ? null : () => _responder(id, true),
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
}
