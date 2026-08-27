import 'package:flutter/material.dart';

class Suggesto extends StatefulWidget {
  const Suggesto({super.key});

  @override
  State<Suggesto> createState() => _SuggestoState();
}

class _SuggestoState extends State<Suggesto> {
  //cria o modelo do bloco, depois só precisa colocar os valoers lá em baixo
  static Widget bloco({
    required String titulo,
    required IconData icone,
    required String texto,
    List<String>? tags, // assim que faz um parametro ser opcional
  }) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color.fromARGB(104, 47, 4, 116),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 25),
          //edita o icone
          Icon(icone, color: Color.fromARGB(255, 147, 100, 236), size: 32),
          SizedBox(height: 10),
          //edita o titulo
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: "Syne",
            ),
          ),
          Divider(
            color: Color.fromARGB(255, 101, 26, 177),
            thickness: 1,
            height: 30,
            indent: 4,
            endIndent: 4,
          ),

          //edita o texto
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(169, 255, 255, 255),
              fontSize: 14,
            ),
          ),

          // onde verifica se no bloco lá em baixo a lista de tags vai ter alguma ocisa pra passar
          if (tags != null && tags.isNotEmpty) ...[
            SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tags.map((tag) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(80, 101, 26, 177),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color.fromARGB(120, 147, 100, 236),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Color.fromARGB(255, 147, 100, 236),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          SizedBox(height: 25),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF12061E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopoVoltar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 50),

                      Text(
                        "Sobre o Projeto",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontFamily: "PoppinsSemi",
                        ),
                      ),
                      Text(
                        "Como tudo funciona",
                        style: TextStyle(
                          color: Color.fromARGB(255, 147, 100, 236),
                        ),
                      ),

                      SizedBox(height: 40),

                      bloco(
                        titulo: "Missão",
                        icone: Icons.flag_outlined,
                        texto:
                            "Aproximar clientes e estabelecimentos por meio de um canal direto, organizado e eficiente de sugestões e feedbacks, transformando opiniões em decisões e melhorias reais.",
                      ),
                      SizedBox(height: 30),

                      bloco(
                        titulo: "Visão",
                        icone: Icons.visibility_outlined,
                        texto:
                            "Ser o elo que transforma a opinião do cliente em melhoria real para as empresas. Queremos que escutar quem compra vire rotina em negócios que buscam crescer com propósito.",
                      ),
                      SizedBox(height: 30),

                      bloco(
                        titulo: "Valores",
                        icone: Icons.favorite_border,
                        texto:
                            "Acreditamos em transparência, conexão real e respeito mútuo entre quem dá e quem recebe o feedback. Para nós, nenhuma ideia ou sugestão deve ser descartada.",
                      ),
                      SizedBox(height: 30),

                      bloco(
                        icone: Icons.desktop_windows_outlined,
                        titulo: "Desktop (Windows)",
                        texto:
                            "Aplicação nativa em Electron com React para interfaces modernas e fluidas no ambiente Windows.",
                        tags: ["Electron", "React"],
                      ),
                      SizedBox(height: 30),

                      bloco(
                        icone: Icons.language,
                        titulo: "Web",
                        texto:
                            "Interface responsiva construída com HTML, CSS e JavaScript, compatível com todos os navegadores modernos.",
                        tags: ["HTML5", "CSS3", "JavaScript"],
                      ),
                      SizedBox(height: 30),

                      bloco(
                        icone: Icons.phone_android_outlined,
                        titulo: "Mobile",
                        texto:
                            "Aplicativo em Flutter com suporte a Android e iOS a partir de uma única base de código otimizada.",
                        tags: ["Flutter", "Dart", "Android · iOS"],
                      ),
                      SizedBox(height: 30),

                      bloco(
                        icone: Icons.storage_outlined,
                        titulo: "Banco de Dados",
                        texto:
                            "Integração via SQL para armazenamento estruturado de usuários, estabelecimentos, sugestões e métricas.",
                        tags: ["SQL", "Autenticação", "Validação"],
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
