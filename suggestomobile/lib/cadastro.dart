import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cores.dart';
import 'mascaras.dart';
import 'listaUsuarios.dart';

// Cadastro de cliente (ver Suggesto - Web/Web/cadastro.html). Contas de
// administrador não são criadas por aqui: no site, virar administrador
// significa escolher um plano e cadastrar um estabelecimento primeiro — um
// admin só usa o mobile pra entrar numa conta que já existe (ver login.dart).
class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _formKey = GlobalKey<FormState>();

  final usuarioController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final cepController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  String? erroGeral;

  @override
  void dispose() {
    usuarioController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    cepController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  void criar() {
    setState(() => erroGeral = null);
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    if (usuariosCadastrados.any((u) => u['email'] == email)) {
      setState(() => erroGeral = "Este e-mail já está cadastrado.");
      return;
    }

    usuariosCadastrados.add({
      'nome': usuarioController.text.trim(),
      'username': usuarioController.text.trim(),
      'email': email,
      'senha': senhaController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'cep': cepController.text.trim(),
      'cidade': cidadeController.text.trim(),
      'estado': estadoController.text.trim(),
      'tipo': 'cliente',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Conta criada com sucesso!", style: TextStyle(fontFamily: "Poppins")),
        backgroundColor: Cores.verdeFundo,
      ),
    );

    Navigator.pushNamed(context, '/home_cliente');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/balaologo.png", width: 42, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Image.asset("assets/images/escritalogo.png", height: 28, fit: BoxFit.contain),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
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
                          "Criar conta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: "PoppinsBold",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Cadastre-se para enviar sugestões e acompanhar respostas dos seus estabelecimentos favoritos",
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins"),
                        ),

                        const SizedBox(height: 20),

                        _rotulo("Nome de usuário"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: usuarioController,
                          hint: "Ex.: joao.silva",
                          validador: _usuarioValidador,
                        ),

                        const SizedBox(height: 16),

                        _rotulo("E-mail"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: emailController,
                          hint: "seuemail@exemplo.com",
                          teclado: TextInputType.emailAddress,
                          validador: _emailValidador,
                        ),

                        const SizedBox(height: 16),

                        _rotulo("Telefone"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: telefoneController,
                          hint: "(00) 00000-0000",
                          teclado: TextInputType.phone,
                          formatadores: [TelefoneFormatter()],
                          validador: _telefoneValidador,
                        ),

                        const SizedBox(height: 16),

                        _rotulo("CEP"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: cepController,
                          hint: "00000-000",
                          teclado: TextInputType.number,
                          formatadores: [CepFormatter()],
                          validador: _cepValidador,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _rotulo("Cidade"),
                                  const SizedBox(height: 8),
                                  _campo(controller: cidadeController, hint: "Sua cidade", validador: _obrigatorio),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _rotulo("Estado"),
                                  const SizedBox(height: 8),
                                  _campo(
                                    controller: estadoController,
                                    hint: "UF",
                                    maxLength: 2,
                                    capitalizar: true,
                                    validador: _estadoValidador,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _rotulo("Senha"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: senhaController,
                          hint: "Mínimo 6 caracteres",
                          oculto: !senhaVisivel,
                          sufixo: IconButton(
                            icon: Icon(
                              senhaVisivel ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => senhaVisivel = !senhaVisivel),
                          ),
                          validador: _senhaValidador,
                        ),

                        const SizedBox(height: 16),

                        _rotulo("Confirmar senha"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: confirmarSenhaController,
                          hint: "Repita sua senha",
                          oculto: !confirmarSenhaVisivel,
                          sufixo: IconButton(
                            icon: Icon(
                              confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => confirmarSenhaVisivel = !confirmarSenhaVisivel),
                          ),
                          validador: (v) => v != senhaController.text ? "As senhas não coincidem." : null,
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
                            onPressed: criar,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Cores.roxoBotao,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Criar conta",
                              style: TextStyle(color: Colors.white, fontFamily: "PoppinsBold", fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        text: "Já tem uma conta? ",
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins"),
                        children: [
                          TextSpan(
                            text: "Entrar",
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
    int? maxLength,
    bool capitalizar = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      inputFormatters: formatadores,
      maxLength: maxLength,
      textCapitalization: capitalizar ? TextCapitalization.characters : TextCapitalization.none,
      validator: validador,
      style: const TextStyle(color: Colors.white, fontFamily: "Poppins"),
      decoration: InputDecoration(
        counterText: "",
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

  // ── Validações — mesmas regras usadas no formulário web (ver cadastro.js
  //    e AuthController.java no backend) ───────────────────────────────────

  String? _obrigatorio(String? v) => (v == null || v.trim().isEmpty) ? "Campo obrigatório." : null;

  String? _usuarioValidador(String? v) {
    final valor = v?.trim() ?? "";
    if (valor.isEmpty) return "Informe um nome de usuário.";
    if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(valor)) {
      return "Use de 3 a 30 letras, números, pontos ou underscores.";
    }
    return null;
  }

  String? _emailValidador(String? v) {
    final valor = v?.trim() ?? "";
    if (valor.isEmpty) return "Informe seu e-mail.";
    if (!valor.contains("@") || !valor.contains(".")) return "Digite um e-mail válido.";
    return null;
  }

  String? _telefoneValidador(String? v) {
    final digitos = (v ?? "").replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return "Informe seu telefone.";
    if (!RegExp(r'^[1-9][1-9](?:9\d{8}|[2-5]\d{7})$').hasMatch(digitos)) {
      return "Telefone inválido. Inclua o DDD.";
    }
    return null;
  }

  String? _cepValidador(String? v) {
    final digitos = (v ?? "").replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return "Informe o CEP.";
    if (digitos.length != 8) return "CEP inválido.";
    return null;
  }

  String? _estadoValidador(String? v) {
    final valor = v?.trim() ?? "";
    if (valor.length != 2) return "UF deve ter 2 letras.";
    return null;
  }

  String? _senhaValidador(String? v) {
    final valor = v ?? "";
    if (valor.isEmpty) return "Crie uma senha.";
    if (valor.length < 6) return "Mínimo de 6 caracteres.";
    return null;
  }
}
