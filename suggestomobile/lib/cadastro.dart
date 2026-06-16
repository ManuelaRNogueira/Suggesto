import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'listaUsuarios.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();


  String tipoUsuario = 'cliente';
  bool termosAceitos = false;
  bool notificacoes = false;
  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  String mensagemErro = "";

  void criar() {
    String email = emailController.text.trim();
    String senha = senhaController.text.trim();
    String confirmar = confirmarSenhaController.text.trim();

    if (email.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      setState(() => mensagemErro = "Preencha todos os campos.");
      return;
    }

    if (senha.length < 8) {
      setState(() => mensagemErro = "A senha deve ter no mínimo 8 caracteres.");
      return;
    }

    if (senha != confirmar) {
      setState(() => mensagemErro = "As senhas não coincidem.");
      return;
    }

    if (!termosAceitos) {
      setState(() => mensagemErro = "Você deve aceitar os termos de uso.");
      return;
    }

    // Verifica se email já existe
    for (var u in usuariosCadastrados) {
      if (u['email'] == email) {
        setState(() => mensagemErro = "Este email já está cadastrado.");
        return;
      }
    }

    // Salva no vetor global
    usuariosCadastrados.add({
      'email': email,
      'senha': senha,
      'tipo': tipoUsuario,
      'notificacoes': notificacoes,
      'termosAceitos': termosAceitos,
    });
    
    print("===========================================");
    print("Email: $email");
    print("Senha: $senha");
    print("Tipo de usuário: $tipoUsuario");
    print("Notificações: $notificacoes");
    print("Termos: $termosAceitos");
    print("===========================================");


    setState(() => mensagemErro = "");

  // MENSAGEM DE SUCESSO
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Conta criada com sucesso!", style: TextStyle(fontFamily: "Poppins"),),
        backgroundColor: Color(0xFF2D5A27),
      ),
    );

    Navigator.pushNamed(context, '/home_cliente');
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromRGBO(18, 6, 30, 1),
    body: Stack(
      children: [

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // TITULO
                const Text(
                  "Criar conta",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: "PoppinsBold",
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                //EMAIL
                SizedBox(
                  width: 400,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Email:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color.fromARGB(220, 255, 255, 255),
                    ),
                    decoration: InputDecoration(
                      hintText: "Digite um email válido",
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(120, 255, 255, 255),
                        fontSize: 13,
                        fontFamily: "Poppins",
                      ),
                      fillColor: const Color.fromARGB(123, 88, 8, 129),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF7B2FBE),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                //SENHA
                SizedBox(
                  width: 400,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Senha:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: senhaController,
                    obscureText: !senhaVisivel,
                    style: const TextStyle(
                      color: Color.fromARGB(220, 255, 255, 255),
                    ),
                    decoration: InputDecoration(
                      hintText: "Mínimo 8 caracteres",
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(120, 255, 255, 255),
                        fontSize: 13,
                        fontFamily: "Poppins",
                      ),
                      fillColor: const Color.fromARGB(123, 88, 8, 129),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF7B2FBE),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          senhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color.fromARGB(160, 255, 255, 255),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            senhaVisivel = !senhaVisivel;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // CONFIRMAR SENHA
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: confirmarSenhaController,
                    obscureText: !confirmarSenhaVisivel,
                    style: const TextStyle(
                      color: Color.fromARGB(220, 255, 255, 255),
                    ),
                    decoration: InputDecoration(
                      hintText: "Repita a senha",
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(120, 255, 255, 255),
                        fontSize: 13,
                        fontFamily: "Poppins",
                      ),
                      fillColor: const Color.fromARGB(123, 88, 8, 129),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF7B2FBE),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          confirmarSenhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color.fromARGB(160, 255, 255, 255),
                        ),
                        onPressed: () {
                          setState(() {
                            confirmarSenhaVisivel =
                                !confirmarSenhaVisivel;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // TIPO DE USUARIO
                SizedBox(
                  width: 400,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Quero me cadastrar como:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(123, 88, 8, 129),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text(
                                "Cliente",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Poppins",
                                ),
                              ),
                              value: 'cliente',
                              groupValue: tipoUsuario,
                              activeColor: Color(0xFF9B59D0),
                              onChanged: (value) {
                                setState(() {
                                  tipoUsuario = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text(
                                "Administrador",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Poppins",
                                ),
                              ),
                              value: 'administrador',
                              groupValue: tipoUsuario,
                              activeColor: Color(0xFF9B59D0),
                              onChanged: (value) {
                                setState(() {
                                  tipoUsuario = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SWITCH
                SizedBox(
                  width: 400,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Receber notificações",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                        ),
                      ),
                      Switch(
                        value: notificacoes,
                        activeColor: const Color(0xFF9B59D0),
                        onChanged: (value) {
                          setState(() {
                            notificacoes = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // CHECKBOX
                SizedBox(
                  width: 400,
                  child: Row(
                    children: [
                      Checkbox(
                        value: termosAceitos,
                        activeColor: const Color(0xFF9B59D0),
                        onChanged: (value) {
                          setState(() {
                            termosAceitos = value!;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Aceito os termos de uso",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (mensagemErro.isNotEmpty)
                  Text(
                    mensagemErro,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),

                const SizedBox(height: 20),

                // BOTAO
                ElevatedButton(
                  onPressed: criar,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(120, 42),
                    backgroundColor: const Color(0xFF6B21A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Criar",
                    style: TextStyle(
                      color: Color.fromARGB(220, 239, 224, 238),
                      fontFamily: "PoppinsBold",
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Já tem uma conta? Entrar",
                    style: TextStyle(
                      color: Color(0xFF9B59D0),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF9B59D0),
                      fontFamily: "Poppins",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // LOGO
        Positioned(
          top: 35,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/balaologo.png",
                width: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Image.asset(
                "assets/images/escritalogo.png",
                height: 35,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}}