import 'package:flutter/material.dart';
import 'cores.dart';

// Nomes e cores de cada status de sugestão, num só lugar — usado na tela
// inicial do admin, na lista de sugestões e nos detalhes.
// Só existem 3 status de verdade no backend (ver AvaliacaoController/
// "statusUi": pendente | implementado | recusado) — nada de "em análise".
class EstiloStatus {
  final String rotulo;
  final Color cor;
  final Color corFundo;
  const EstiloStatus(this.rotulo, this.cor, this.corFundo);
}

const Map<String, EstiloStatus> _estilos = {
  'pendente': EstiloStatus('Pendente', Cores.amarelo, Color(0x29FFB800)),
  'implementado': EstiloStatus('Implementado', Cores.verde, Cores.verdeFundo),
  'recusado': EstiloStatus('Recusado', Color(0xFFFF5252), Color(0x29FF5252)),
};

EstiloStatus estiloDoStatus(String chave) => _estilos[chave] ?? _estilos['pendente']!;

// Texto maior, usado no selo de destaque da tela de detalhes.
String descricaoDoStatus(String chave) {
  switch (chave) {
    case 'implementado':
      return 'Implementada';
    case 'recusado':
      return 'Recusada';
    default:
      return 'Pendente de análise';
  }
}

Widget pillStatus(String chave, {double fontSize = 10}) {
  final estilo = estiloDoStatus(chave);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: estilo.corFundo, borderRadius: BorderRadius.circular(6)),
    child: Text(
      estilo.rotulo,
      style: TextStyle(color: estilo.cor, fontSize: fontSize, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
    ),
  );
}
