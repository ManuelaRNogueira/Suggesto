import 'package:flutter/material.dart';
import 'listaUsuarios.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  String mensagemErro = "";

  void entrar() {
    String email = emailController.text.trim();
    String senha = senhaController.text.trim();

    // VE SE OS CAMPOS ESTÃO VAZIOS
    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        mensagemErro = "Preencha todos os campos.";
      });
      return;
    }

    // PROCURA O USUÁRIO
    bool encontrou = false;
    for (var usuario in usuariosCadastrados) {
      if (usuario['email'] == email && usuario['senha'] == senha) {
        encontrou = true;
        break;
      }
    }

    if (encontrou) {
      setState(() {
        mensagemErro = "";
      });
      Navigator.pushNamed(context, '/home_cliente');
    } else {
      setState(() {
        mensagemErro = "Email ou senha incorretos.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromRGBO(20, 7, 32, 1),
    body: Center(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // TITULO
                  const Text(
                    "Entrar", 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: "PoppinsBold",
                    ),
                  ),
                  const SizedBox(height: 30),

                  // CAMPO EMAIL
                  SizedBox(
                    width: 400,
                    child: TextField(
                      controller: emailController,
                      style: const TextStyle(color: Color.fromARGB(186, 255, 255, 255)),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Color.fromARGB(139, 255, 255, 255), fontSize: 14, fontFamily: "Poppins"),
                        fillColor: const Color.fromARGB(123, 88, 8, 129),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CAMPO SENHA
                  SizedBox(
                    width: 400,
                    child: TextField(
                      controller: senhaController,
                      obscureText: true,
                      style: const TextStyle(color: Color.fromARGB(186, 255, 255, 255)),
                      decoration: InputDecoration(
                        labelText: "Senha",
                        labelStyle: const TextStyle(color: Color.fromARGB(139, 255, 255, 255), fontSize: 14, fontFamily: "Poppins"),
                        fillColor: const Color.fromARGB(123, 88, 8, 129),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // MENSAGEM DE ERRO
                  if (mensagemErro.isNotEmpty)
                    Text(
                      mensagemErro,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: "Poppins"),
                    ),

                  const SizedBox(height: 20),

                  // BOTAO ENTRAR
                  ElevatedButton(
                    onPressed: entrar,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(120, 40),
                      backgroundColor: const Color.fromARGB(187, 73, 8, 138),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Entrar",
                      style: TextStyle(
                        color: Color.fromARGB(200, 239, 224, 238),
                        fontFamily: "PoppinsBold",
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LINK PARA CADASTRO
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/cadastro');
                    },
                    child: const Text(
                      "Não tem conta? Cadastre-se",
                      style: TextStyle(
                        color: Color(0xFF9B59D0),
                        fontSize: 13,
                        fontFamily: "Poppins",
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF9B59D0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // IMAGENS
          Positioned(top: 35, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Image.asset("assets/images/balaologo.png", width: 50, fit: BoxFit.contain),
                const SizedBox(width: 8),
                Image.asset("assets/images/escritalogo.png", height: 35, fit: BoxFit.contain),
              ],
            ),
          ),

        ],
      ),
    ),
  );
  }}