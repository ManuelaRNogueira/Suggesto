import 'package:flutter/material.dart';
import 'cores.dart';
import 'api.dart';
import 'geoUtils.dart';

//cartão de estabelecimento do cliente (usado no Início e nos Locais Salvos)
Widget cardEstabelecimentoCliente({
  required Map<String, dynamic> local,
  required VoidCallback onTap,
  required bool salvo,
  VoidCallback? onToggleFavorito,
  //distância até o usuário, só no "Perto de você" (aparece "· 1,2 km")
  double? distanciaKm,
}) {
  //monta "bairro, cidade · distância" e a nota média
  final fotoUrl = urlFotoEstabelecimento(local['fotoPath'] as String?);
  final cidade = (local['cidade'] as String?) ?? '';
  final bairro = (local['bairro'] as String?) ?? '';
  var localizacao = [bairro, cidade].where((s) => s.isNotEmpty).join(', ');
  if (distanciaKm != null) {
    final distanciaTexto = formatarDistancia(distanciaKm);
    localizacao = localizacao.isEmpty
        ? distanciaTexto
        : '$localizacao · $distanciaTexto';
  }
  final nota = (local['mediaAvaliacoes'] as num?)?.toStringAsFixed(1) ?? '—';

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E32),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //foto com sombra escura embaixo
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: fotoUrl != null
                    ? Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImagem(),
                      )
                    : _placeholderImagem(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          //infos
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //nome e localização
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (local['nome'] as String?) ?? 'Sem nome',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '| $localizacao',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                //direita: categoria, nota e botão de favoritar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1A6A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (local['categoria'] as String?) ?? '—',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A27),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFF4CAF50),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                nota,
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onToggleFavorito,
                          child: Icon(
                            salvo ? Icons.bookmark : Icons.bookmark_border,
                            color: salvo ? Cores.roxo : Colors.white54,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

//ícone de loja no lugar da foto
Widget _placeholderImagem() {
  return Container(
    color: const Color(0xFF2A1A4A),
    child: const Icon(Icons.storefront, color: Colors.white38, size: 40),
  );
}
