import 'package:flutter/material.dart';
import 'cores.dart';

//3 cartões lado a lado: pendentes, implementadas e recusadas, com a %
//usado no Início do admin e no detalhe do estabelecimento
Widget cartoesStatusAdm({
  required int total,
  required int pendentes,
  required int implementados,
  required int recusados,
}) {
  //cálculo de porcentagem: quanto cada status é do total
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

//um cartão: barrinha colorida, nome, quantidade e "% do total"
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
