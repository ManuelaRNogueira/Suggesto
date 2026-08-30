import 'package:flutter/material.dart';
import 'cores.dart';
import 'statusSugestao.dart';
import 'formatacao.dart';

// Card de sugestão do painel admin — usado tanto na tela "Sugestões"
// (sugestoesAdm.dart) quanto nas "Sugestões Recentes" da tela "Início"
// (inicioAdm.dart). Uma implementação só: qualquer ajuste de design aqui já
// vale pras duas telas. A única diferença é `mostrarEstabelecimento`: em
// "Início" o estabelecimento ainda não foi escolhido em nenhum filtro, então
// o card precisa deixar isso claro; em "Sugestões" o estabelecimento já é
// selecionado no filtro da tela, então repeti-lo em cada card seria redundante.
Widget cartaoSugestaoAdm({
  required Map<String, dynamic> sugestao,
  required VoidCallback onTap,
  bool mostrarEstabelecimento = false,
}) {
  final categoria = (sugestao['categoria'] as String?) ?? 'Sem categoria';
  final estabelecimento = sugestao['estabelecimento'] as String?;
  final meta =
      mostrarEstabelecimento &&
          estabelecimento != null &&
          estabelecimento.isNotEmpty
      ? '$categoria · $estabelecimento'
      : 'Categoria: $categoria';

  return GestureDetector(
    onTap: onTap,
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
              pillStatus((sugestao['statusUi'] as String?) ?? 'pendente'),
              Text(
                formatarData(sugestao['dataAvaliacao'] as String?),
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
            tituloSugestao(sugestao['comentario'] as String?),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            meta,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              (sugestao['autor'] as String?) ?? 'Anônimo',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
