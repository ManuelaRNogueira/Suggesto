import 'package:flutter/material.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'api.dart';

// Card de estabelecimento do painel admin — foto, categoria, "Inativo" (se
// for o caso), nome e endereço. Usado na lista de Estabelecimentos
// (estabelecimentosAdm.dart) e no resumo de "Estabelecimentos vinculados" do
// Perfil (perfilAdm.dart), pra manter o mesmo visual nos dois lugares.
Widget cartaoEstabelecimentoAdm(
  Map<String, dynamic> e, {
  required VoidCallback onTap,
}) {
  final nome = (e['nome'] as String?) ?? 'Estabelecimento';
  final categoria = (e['categoria'] as String?) ?? '';
  final fotoUrl = urlFotoEstabelecimento(e['fotoPath'] as String?);
  final endereco = formatarEndereco(e);
  final ativo = e['ativo'] as bool?;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 120,
            child: fotoUrl != null
                ? Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholderFoto(),
                  )
                : _placeholderFoto(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (categoria.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                    if (ativo == false)
                      Text(
                        'Inativo',
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.8),
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'PoppinsSemi',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        endereco,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
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

Widget _placeholderFoto() {
  return Container(
    color: Cores.borda,
    child: const Icon(Icons.storefront, color: Colors.white38, size: 32),
  );
}
