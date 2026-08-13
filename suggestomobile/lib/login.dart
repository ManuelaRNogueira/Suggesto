import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cores.dart';
import 'listaUsuarios.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool senhaVisivel = false;
  String? erroGeral;

  void entrar() {
    setState(() => erroGeral = null);
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    Map<String, dynamic>? usuario;
    for (final u in usuariosCadastrados) {
      if (u['email'] == email && u['senha'] == senha) {
        usuario = u;
        break;
      }
    }

    if (usuario == null) {
      setState(() => erroGeral = "E-mail ou senha incorretos.");
      return;
    }

    final destino = usuario['tipo'] == 'administrador' ? '/inicioAdm' : '/home_cliente';
    Navigator.pushNamed(context, destino);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/balaologo.png", width: 46, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Image.asset("assets/images/escritalogo.png", height: 32, fit: BoxFit.contain),
                    ],
                  ),

                  const SizedBox(height: 36),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Cores.cartao,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Cores.borda),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Entrar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: "PoppinsBold",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Acesse sua conta para continuar",
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins"),
                        ),

                        const SizedBox(height: 24),

                        _rotulo("E-mail"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: emailController,
                          hint: "seuemail@exemplo.com",
                          teclado: TextInputType.emailAddress,
                          validador: (v) {
                            final valor = v?.trim() ?? "";
                            if (valor.isEmpty) return "Informe seu e-mail.";
                            if (!valor.contains("@") || !valor.contains(".")) {
                              return "Digite um e-mail válido.";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _rotulo("Senha"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: senhaController,
                          hint: "Digite sua senha",
                          oculto: !senhaVisivel,
                          sufixo: IconButton(
                            icon: Icon(
                              senhaVisivel ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => senhaVisivel = !senhaVisivel),
                          ),
                          validador: (v) => (v == null || v.isEmpty) ? "Informe sua senha." : null,
                        ),

                        if (erroGeral != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            erroGeral!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: "Poppins"),
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: entrar,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Cores.roxoBotao,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Entrar",
                              style: TextStyle(color: Colors.white, fontFamily: "PoppinsBold", fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/cadastro'),
                    child: const Text.rich(
                      TextSpan(
                        text: "Não tem conta? ",
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins"),
                        children: [
                          TextSpan(
                            text: "Cadastre-se",
                            style: TextStyle(
                              color: Cores.roxo,
                              fontFamily: "PoppinsSemi",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotulo(String texto) {
    return Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: "Poppins"));
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validador,
    TextInputType? teclado,
    bool oculto = false,
    Widget? sufixo,
    List<TextInputFormatter>? formatadores,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      inputFormatters: formatadores,
      validator: validador,
      style: const TextStyle(color: Colors.white, fontFamily: "Poppins"),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, fontFamily: "Poppins"),
        filled: true,
        fillColor: Cores.campo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: sufixo,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Cores.campoFoco, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: "Poppins"),
      ),
    );
  }
}
