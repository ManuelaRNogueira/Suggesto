import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'formatacao.dart';
import 'api.dart';

// Detalhe de uma sugestão, com os botões pra trocar o status — versão mobile
// da mesma ação que existe na tela de Sugestões do desktop
// (Suggesto_DesktopReact/renderer/src/pages/admin/Sugestoes.jsx, atualizarStatusSugestao).
// `sugestao` é o mesmo Map recebido de GET /api/admin/sugestoes (ou do bloco
// "sugestoesRecentes" de GET /api/admin/metricas) — mesma forma nos dois casos.
class DetalhesSugestaoAdm extends StatefulWidget {
  final Map<String, dynamic> sugestao;

  const DetalhesSugestaoAdm({super.key, required this.sugestao});

  @override
  State<DetalhesSugestaoAdm> createState() => _DetalhesSugestaoAdmState();
}

class _DetalhesSugestaoAdmState extends State<DetalhesSugestaoAdm> {
  bool trocandoStatus = false;
  String? erro;

  static const _statusDisponiveis = ['pendente', 'implementado', 'recusado'];

  Future<void> _mudarStatus(String novoStatus) async {
    setState(() {
      trocandoStatus = true;
      erro = null;
    });
    try {
      final id = (widget.sugestao['id'] as num).toInt();
      await atualizarStatusAvaliacao(id, novoStatus);
      setState(() {
        widget.sugestao['statusUi'] = novoStatus;
        widget.sugestao['status'] = novoStatus;
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => trocandoStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sugestao;
    final statusAtual = (s['statusUi'] as String?) ?? 'pendente';
    final outrosStatus = _statusDisponiveis
        .where((st) => st != statusAtual)
        .toList();
    final nota = (s['nota'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopoVoltar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detalhes da Sugestão',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PoppinsSemi',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _cartaoEstabelecimento(s),
                    const SizedBox(height: 16),
                    _seloStatus(statusAtual),
                    const SizedBox(height: 20),
                    _cartaoDetalhe(s, nota),
                    const SizedBox(height: 24),
                    if (erro != null) ...[
                      Text(
                        erro!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (trocandoStatus)
                      const CircularProgressIndicator(color: Cores.roxo)
                    else
                      _botoesStatus(outrosStatus),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seta de voltar isolada, mesmo padrão de sobrenos.dart/suggesto.dart —
  // essa tela é um detalhe, sem Bottom Navigation.
  Widget _buildTopoVoltar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E0E32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A1A4A)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card do estabelecimento — identifica de onde veio o feedback antes do
  // card de detalhes. Foto e nome reais, vindos da própria sugestão
  // (estabelecimento/estabelecimentoFotoPath, AdminService.resumirSugestao).
  Widget _cartaoEstabelecimento(Map<String, dynamic> s) {
    final nome = (s['estabelecimento'] as String?) ?? 'Estabelecimento';
    final fotoUrl = urlFotoEstabelecimento(
      s['estabelecimentoFotoPath'] as String?,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: fotoUrl != null
                  ? Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholderEstabelecimento(),
                    )
                  : _placeholderEstabelecimento(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderEstabelecimento() {
    return Container(
      color: Cores.tag,
      child: const Icon(Icons.storefront, color: Colors.white38, size: 22),
    );
  }

  Widget _seloStatus(String status) {
    final estilo = estiloDoStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: estilo.corFundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: estilo.cor, size: 15),
          const SizedBox(width: 6),
          Text(
            descricaoDoStatus(status),
            style: TextStyle(
              color: estilo.cor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoDetalhe(Map<String, dynamic> s, int? nota) {
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
          Text(
            tituloSugestao(s['comentario'] as String?),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (nota != null) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < nota ? Icons.star : Icons.star_border,
                  color: i < nota ? Cores.amarelo : Colors.white24,
                  size: 15,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            (s['comentario'] as String?)?.trim().isNotEmpty == true
                ? s['comentario']
                : 'Sem descrição.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Categoria: ${s['categoria'] ?? 'Sem categoria'}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          if (s['resposta'] != null &&
              (s['resposta'] as String).trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.tag,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resposta enviada',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['resposta'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Cores.borda, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Cores.tag,
                child: Text(
                  _iniciais((s['autor'] as String?) ?? '?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'PoppinsSemi',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (s['autor'] as String?) ?? 'Anônimo',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                formatarDataHora(s['dataAvaliacao'] as String?),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    final primeiras = partes
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '');
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
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'implementado':
        return Icons.check_circle_outline;
      case 'recusado':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }
}
