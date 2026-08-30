import 'package:flutter/material.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'api.dart';

// Versão mobile, só de leitura, da tela de detalhes de estabelecimento do
// desktop (Suggesto_DesktopReact/renderer/src/pages/DetalhesEstabelecimento.jsx)
// — sem a gestão de sugestões/edição que existe lá, já que isso já tem tela
// própria no mobile (Sugestões, com filtro por estabelecimento).
// `estabelecimento` é o mesmo Map de GET /api/estabelecimentos/{id}, já
// carregado pela lista (estabelecimentosAdm.dart) — sem chamada extra aqui.
class DetalhesEstabelecimentoAdm extends StatelessWidget {
  final Map<String, dynamic> estabelecimento;

  const DetalhesEstabelecimentoAdm({super.key, required this.estabelecimento});

  @override
  Widget build(BuildContext context) {
    final e = estabelecimento;
    final nome = (e['nome'] as String?) ?? 'Estabelecimento';
    final categoria = (e['categoria'] as String?) ?? '';
    final fotoUrl = urlFotoEstabelecimento(e['fotoPath'] as String?);
    final endereco = formatarEndereco(e);
    final telefone = (e['telefone'] as String?)?.trim();
    final horario = (e['horarioFuncionamento'] as String?)?.trim();
    final sobre = (e['sobre'] as String?)?.trim();
    final nota = (e['mediaAvaliacoes'] as num?)?.toDouble();
    final ativo = e['ativo'] as bool?;

    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopoVoltar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: fotoUrl != null
                            ? Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderFoto(),
                              )
                            : _placeholderFoto(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (categoria.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Cores.tag,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria,
                              style: const TextStyle(
                                color: Cores.roxo,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (nota != null && nota > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Cores.verdeFundo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Cores.amarelo,
                                  size: 13,
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
                        ],
                        if (ativo == false) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Inativo',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'PoppinsBold',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _linhaInfo(Icons.location_on_outlined, endereco),
                    if (telefone != null && telefone.isNotEmpty)
                      _linhaInfo(Icons.phone_outlined, telefone),
                    if (horario != null && horario.isNotEmpty)
                      _linhaInfo(Icons.schedule_outlined, horario),
                    if (sobre != null && sobre.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _cardSobre(sobre),
                    ],
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
  Widget _buildTopoVoltar(BuildContext context) {
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

  Widget _placeholderFoto() {
    return Container(
      color: Cores.cartao,
      child: const Icon(Icons.storefront, color: Colors.white38, size: 48),
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  Widget _cardSobre(String sobre) {
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
            'Sobre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
      ),
    );
  }
}
