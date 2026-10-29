import 'package:flutter/material.dart';
import 'cores.dart';

//nome e cor de cada status de sugestão (pendente, implementado, recusado)
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

//pega o estilo do status (se não reconhecer, usa o de pendente)
EstiloStatus estiloDoStatus(String chave) => _estilos[chave] ?? _estilos['pendente']!;

//texto mais longo do status, usado na tela de detalhes
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

//etiqueta colorida com o nome do status
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
