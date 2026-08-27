import 'package:flutter/material.dart';

class Sobrenos extends StatefulWidget {
  const Sobrenos({super.key});

  @override
  State<Sobrenos> createState() => _SobrenosState();
}

class _SobrenosState extends State<Sobrenos> {
  Widget _buildTopoVoltar() {
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
      backgroundColor: const Color(0xFF12061E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopoVoltar(),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      Text(
                        "Sobre Nós",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontFamily: "PoppinsSemi",
                        ),
                      ),
                      Text(
                        "Conheça a equipe por trás do Suggesto",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 147, 100, 236),
                        ),
                      ),
                      SizedBox(height: 30),

                      //DIOGO
                      Container(
                        width: 400,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            104,
                            47,
                            4,
                            116,
                          ), // cor do container
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // borda arredondada
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                "assets/images/diogo.jpg",
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Diogo Damascena",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Syne",
                              ),
                            ),
                            Text(
                              "cl204225@g.unicamp.br",
                              style: TextStyle(
                                color: const Color.fromARGB(94, 235, 235, 235),
                                fontFamily: "Poppins",
                                fontSize: 12,
                              ),
                            ),
                            Divider(
                              color: const Color.fromARGB(255, 101, 26, 177),
                              thickness: 1,
                              height: 40,
                              indent: 20,
                              endIndent: 20,
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Desenvolvedor Backend, responsável pela lógica do sistema, API, integração com banco de dados SQL e desenvolvimento das funcionalidades desktop com Java e Spring Boot.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    169,
                                    255,
                                    255,
                                    255,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      //GABRIEL
                      Container(
                        width: 400,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            104,
                            47,
                            4,
                            116,
                          ), // cor do container
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // borda arredondada
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                "assets/images/gabrielG.jpg",
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Gabriel Gonçalves",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Syne",
                              ),
                            ),
                            Text(
                              "cl204142@g.unicamp.br",
                              style: TextStyle(
                                color: const Color.fromARGB(94, 235, 235, 235),
                                fontFamily: "Poppins",
                                fontSize: 12,
                              ),
                            ),
                            Divider(
                              color: const Color.fromARGB(255, 101, 26, 177),
                              thickness: 1,
                              height: 40,
                              indent: 20,
                              endIndent: 20,
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Desenvolvedor Mobile, responsável pela criação e implementação da versão móvel do Suggesto utilizando Flutter e Dart, com foco em usabilidade, desempenho e integração com os demais módulos do sistema.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    169,
                                    255,
                                    255,
                                    255,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      //MANUELA
                      Container(
                        width: 400,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            104,
                            47,
                            4,
                            116,
                          ), // cor do container
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // borda arredondada
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                "assets/images/manuela.jpg",
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Manuela Nogueira",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Syne",
                              ),
                            ),
                            Text(
                              "cl204065@g.unicamp.br",
                              style: TextStyle(
                                color: const Color.fromARGB(94, 235, 235, 235),
                                fontFamily: "Poppins",
                                fontSize: 12,
                              ),
                            ),
                            Divider(
                              color: const Color.fromARGB(255, 101, 26, 177),
                              thickness: 1,
                              height: 40,
                              indent: 20,
                              endIndent: 20,
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Desenvolvedora Frontend e Designer UI/UX, responsável pela criação da plataforma web do Suggesto, atuando no desenvolvimento das interfaces e da identidade visual utilizando HTML, CSS e JavaScript.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    169,
                                    255,
                                    255,
                                    255,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
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
