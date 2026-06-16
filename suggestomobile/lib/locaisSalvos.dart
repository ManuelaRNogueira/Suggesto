import 'package:flutter/material.dart';
import 'infoLocal.dart';

class LocaisSalvosPage extends StatefulWidget {
  const LocaisSalvosPage({super.key});

  @override
  State<LocaisSalvosPage> createState() => _LocaisSalvosPageState();
}

class _LocaisSalvosPageState extends State<LocaisSalvosPage> {
  final List<Map<String, dynamic>> locais = [
    {
      'nome': 'Big Jack Hamburgueria',
      'bairro': 'Bairro Castelo, Campinas',
      'categoria': 'Restaurantes',
      'nota': 4.8,
      'tags': ['Hambúrguer', 'Delivery'],
      'salvoHa': 'Salvo há 2 dias',
      'imagem': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&q=80',
      'salvo': true,
      'lat': -22.88981704589304,
      'lng': -47.07628634133093,
      'endereco': 'R. Oliveira Cardoso, 376 - Jardim Chapadão, Campinas - SP, 13070-148',
      'horario': '11h - 23h',
      'telefone': '(19) 3212-3025',
    },
    {
      'nome': 'Café do Centro',
      'bairro': 'Rua das Flores, Campinas',
      'categoria': 'Cafés',
      'nota': 4.7,
      'tags': ['Especialidade', 'Wi-fi'],
      'salvoHa': 'Salvo há 1 semana',
      'imagem': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&q=80',
      'salvo': true,
      'lat': -22.902932790424725,
      'lng': -47.059543363884586,
      'endereco': 'Rua Barão de Jaguara, 1302 - Centro, Campinas - SP, 13015-002',
      'horario': '7h - 20h',
      'telefone': '(19) 3231-4079',
    },
    {
      'nome': 'Panobianco Academia',
      'bairro': 'Centro, Campinas',
      'categoria': 'Academias',
      'nota': 4.5,
      'tags': ['Musculação', '24h'],
      'salvoHa': 'Salvo há 2 semanas',
      'imagem': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
      'salvo': true,
      'lat': -22.905673074198525,
      'lng': -47.05910106144178,
      'endereco': 'Av Francisco Glicério 964 Sobre loja - Centro, Campinas - SP, 13012-100',
      'horario': '6h - 22h',
      'telefone': '(19) 99202-4114',
    },
    {
      'nome': 'Cantina Italiana',
      'bairro': 'Vila Nova, Campinas',
      'categoria': 'Restaurantes',
      'nota': 4.9,
      'tags': ['Italiana', 'Família'],
      'salvoHa': 'Salvo há 3 dias',
      'imagem': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
      'salvo': true,
      'lat': -22.893581437970333,
      'lng': -47.05247901520925,
      'endereco': 'Av. Cel. Silva Telles, 514 - Cambuí, Campinas - SP, 13024-001',
      'horario': '11h - 23h',
      'telefone': '(19) 3252-0845',
    },
    {
      'nome': 'Brew Specialty Coffee',
      'bairro': 'Cambuí, Campinas',
      'categoria': 'Cafés',
      'nota': 4.6,
      'tags': ['Artesanal', 'Pet friendly'],
      'salvoHa': 'Salvo há 5 dias',
      'imagem': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
      'salvo': true,
      'lat': -22.887983566179436,
      'lng': -47.04989764423815,
      'endereco': 'R. dos Alecrins, 659 - Cambuí, Campinas - SP, 13024-411',
      'horario': '9h - 18h',
      'telefone': '(19) 97148-2323',
    },
    {
      'nome': 'SmartFit Campinas',
      'bairro': 'Shopping Dom Pedro, Campinas',
      'categoria': 'Academias',
      'nota': 4.3,
      'tags': ['Musculação', 'Cardio'],
      'salvoHa': 'Salvo há 1 mês',
      'imagem': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
      'salvo': true,
      'lat': -21.15080135904626,
      'lng': -47.82537453276064,
      'endereco': 'Shopping Mall Dom Pedro I - Av. Dom Pedro I, 1550 - Ipiranga, Ribeirão Preto - SP, 14055-620',
      'horario': '24h',
      'telefone': 'Sem número informado',
    },
  ];

  double get mediaAvaliacao {
    if (locais.isEmpty) return 0;
    final soma = locais.fold<double>(0, (sum, l) => sum + (l['nota'] as double));
    return double.parse((soma / locais.length).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const SizedBox(height: 24),
                  _buildSectionTitle(),
                  const SizedBox(height: 16),
                  _buildLocaisGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  // ─── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB8C8E8),
            Color(0xFFD4A8D8),
            Color(0xFFE8D0F0),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1A0A2E),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Locais Salvos',
                    style: TextStyle(
                      color: Color(0xFF1A0A2E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1A0A2E), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Sua coleção',
                  style: TextStyle(
                    color: const Color(0xFF1A0A2E).withOpacity(0.55),
                    fontSize: 13,
                    fontFamily: "PoppinsSemi",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1A4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A2A7A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Título da seção ───────────────────────────────────────────────
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Seus estabelecimentos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "PoppinsSemi",
            ),
          ), 
        ],
      ),
    );
  }

  // ─── Grid de locais ────────────────────────────────────────────────
  Widget _buildLocaisGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: locais.length,
        itemBuilder: (context, index) => _buildLocalCard(locais[index]),
      ),
    );
  }

  // ─── Card do local ─────────────────────────────────────────────────
  Widget _buildLocalCard(Map<String, dynamic> local) {
    final tags = local['tags'] as List<String>;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InfoLocalPage(local: local)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E0E32),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagem ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(local['imagem'], fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        local['categoria'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        local['salvo'] = !(local['salvo'] as bool);
                      }),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59D0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Infos ────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local['nome'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: "PoppinsSemi",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white38, size: 10),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            local['bairro'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 10,
                              fontFamily: "Poppins"
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1A4A),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: Colors.white60, fontSize: 9, fontFamily: "Poppins"),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A27),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFF4CAF50), size: 11),
                              const SizedBox(width: 2),
                              Text(
                                local['nota'].toString(),
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      local['salvoHa'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}