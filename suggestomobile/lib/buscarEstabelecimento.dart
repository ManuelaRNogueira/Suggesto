import 'package:flutter/material.dart';
import 'infoLocal.dart';
import 'api.dart';

// 👇 Nome alterado para BuscarEstabelecimento
class BuscarEstabelecimento extends StatefulWidget {
  final List<Map<String, dynamic>> locais;

  const BuscarEstabelecimento({super.key, required this.locais});

  @override
  State<BuscarEstabelecimento> createState() => _BuscarEstabelecimentoState();
}

class _BuscarEstabelecimentoState extends State<BuscarEstabelecimento> {
  List<Map<String, dynamic>> _locaisFiltrados = [];

  @override
  void initState() {
    super.initState();
    _locaisFiltrados = widget.locais;
  }
//divide o nome do estabelecimento e faz a pesquisa por palavra, procurando pelas primeiras letras da palavra 
  void _filtrarPesquisa(String textoDigitado) {
  setState(() {
    if (textoDigitado.isEmpty) {
      _locaisFiltrados = widget.locais; // Se apagar, volta tudo
    } else {
      final pesquisa = textoDigitado.toLowerCase();

      _locaisFiltrados = widget.locais.where((local) {
        final nomeDoLocal = local['nome'].toString().toLowerCase();
        
        // 1. Separa o nome do lugar por espaços. 
        // Ex: "panobianco academia" vira ["panobianco", "academia"]
        final palavras = nomeDoLocal.split(' ');

        // 2. Verifica se ALGUMA das palavras começa com o que foi digitado
        return palavras.any((palavra) => palavra.startsWith(pesquisa));
      }).toList();
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Botão de voltar e Título
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Achar um estabelecimento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 20),

              // Barra de Pesquisa
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF23153A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (texto) => _filtrarPesquisa(texto),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Pesquise',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Perto de você',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Lista com os Resultados
              Expanded(
                child: _locaisFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum estabelecimento encontrado :(',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _locaisFiltrados.length,
                        itemBuilder: (context, index) {
                          final local = _locaisFiltrados[index];
                          return _buildLocalCard(local);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildLocalCard(Map<String, dynamic> local) {
    final fotoUrl = urlFotoEstabelecimento(local['fotoPath'] as String?);
    final cidade = (local['cidade'] as String?) ?? '';
    final bairro = (local['bairro'] as String?) ?? '';
    final localizacao = [bairro, cidade].where((s) => s.isNotEmpty).join(', ');
    final nota = (local['mediaAvaliacoes'] as num?)?.toStringAsFixed(1) ?? '—';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InfoLocalPage(local: local),
          ),
        );
      },
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
            // Imagem
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

            // Infos
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e bairro
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

                  // Coluna direita
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5A27),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFF4CAF50), size: 12),
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
                          const Icon(
                            Icons.bookmark_border,
                            color: Colors.white54,
                            size: 18,
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

  Widget _placeholderImagem() {
    return Container(
      color: const Color(0xFF2A1A4A),
      child: const Icon(Icons.storefront, color: Colors.white38, size: 40),
    );
  }
  }
