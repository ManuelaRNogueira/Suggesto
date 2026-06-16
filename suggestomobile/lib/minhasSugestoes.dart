import 'package:flutter/material.dart';
import 'listaSugestoes.dart';

class MinhasSugestoes extends StatefulWidget {
  const MinhasSugestoes({super.key});

  @override
  State<MinhasSugestoes> createState() => _MinhasSugestoesState();
}

class _MinhasSugestoesState extends State<MinhasSugestoes> {
  List<Map<String, String>> get sugestoes => listaSugestoes.lista;

  void removerSugestao(int index) async {
    bool? remover = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF12061E),
          title: Text("Remover sugestão", style: TextStyle(color: Colors.white)),
          content: Text("Deseja remover esta sugestão?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Remover", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (remover == true) {
      setState(() => sugestoes.removeAt(index));
    }
  }

  // WIDGET DO CARD
  Widget sugestao({
    required String local,
    required String imagem,
    required String categoria,
    required String texto,
    required String status,
    required String tempo,
    required String nota,
    required int index,
  }) {
    final notaInt = int.tryParse(nota) ?? 0;

    return Container(
      width: 450,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(104, 47, 4, 116),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imagem.isNotEmpty
                ? Image.network(
                    imagem,
                    width: 95,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImagem(),
                  )
                : _placeholderImagem(),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LINHA DO TOPO: nome + lixeira/status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            local,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "PoppinsSemi",
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(80, 101, 26, 177),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria,
                              style: TextStyle(
                                color: Color.fromARGB(255, 147, 100, 236),
                                fontSize: 12,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => removerSugestao(index),
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        ),
                        SizedBox(height: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: status == "Resolvida" ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // ESTRELAS
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < notaInt ? Icons.star : Icons.star_border,
                      color: i < notaInt ? Color(0xFFFFB800) : Colors.white24,
                      size: 16,
                    );
                  }),
                ),

                SizedBox(height: 10),

                Text(
                  texto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color.fromARGB(190, 255, 255, 255),
                    fontSize: 13,
                    fontFamily: "Poppins",
                  ),
                ),

                SizedBox(height: 15),

                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white54, size: 16),
                    SizedBox(width: 5),
                    Text(tempo, style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImagem() {
    return Container(
      width: 95,
      height: 140,
      decoration: BoxDecoration(
        color: Color(0xFF2A1A4A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(Icons.storefront, color: Colors.white38, size: 32),
    );
  }

  // BOTTOM NAV
  int paginaAtual = 1;
  Widget barraNavegacao() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF12061E),
        border: Border(top: BorderSide(color: Color(0xFF1E0E32), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 0); Navigator.pushNamed(context, '/home_cliente'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.home_filled, color: paginaAtual == 0 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Início", style: TextStyle(color: paginaAtual == 0 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 1); Navigator.pushNamed(context, '/minhasSugestoes'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.forum, color: paginaAtual == 1 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Minhas\nSugestões", textAlign: TextAlign.center, style: TextStyle(color: paginaAtual == 1 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 2); Navigator.pushNamed(context, '/loja'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.monetization_on, color: paginaAtual == 2 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Pontos", style: TextStyle(color: paginaAtual == 2 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 3); Navigator.pushNamed(context, '/perfil'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person, color: paginaAtual == 3 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Perfil", style: TextStyle(color: paginaAtual == 3 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF12061E),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 30),

              Text(
                "Minhas Sugestões",
                style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: "PoppinsSemi"),
              ),

              SizedBox(height: 40),

              ...List.generate(sugestoes.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: sugestao(
                    index: index,
                    local: sugestoes[index]["local"]!,
                    imagem: sugestoes[index]["imagem"]!,
                    categoria: sugestoes[index]["categoria"]!,
                    texto: sugestoes[index]["texto"]!,
                    status: sugestoes[index]["status"]!,
                    tempo: sugestoes[index]["tempo"]!,
                    nota: sugestoes[index]["nota"] ?? "0",
                  ),
                );
              }),

              SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: barraNavegacao(),
    );
  }
}