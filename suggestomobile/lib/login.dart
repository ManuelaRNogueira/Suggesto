import 'package:flutter/material.dart';
import 'cores.dart';
import 'api.dart';
import 'sessao.dart';
import 'cadastro.dart';
import 'entrarEquipe.dart';
import 'entrarCodigo.dart';
import 'esqueciSenha.dart';

//tela de login: confere email e senha na API e manda pra tela certa
class Login extends StatefulWidget {
  //true = veio do "entrar numa equipe": só aceita administrador e depois vai pro código de acesso
  final bool modoEquipe;

  const Login({super.key, this.modoEquipe = false});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool senhaVisivel = false;
  bool entrando = false;
  String? erroGeral;

  //botão Entrar: valida, faz login e decide a rota
  Future<void> entrar() async {
    setState(() => erroGeral = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => entrando = true);
    try {
      final resultado = await login(
        email: emailController.text.trim(),
        senha: senhaController.text.trim(),
      );

      final tipoUsuario = resultado['tipoUsuario'] as String?;
      final idUsuario = (resultado['idUsuario'] as num).toInt();

      //modo equipe: bloqueia quem não é administrador
      if (widget.modoEquipe && tipoUsuario != 'Administrador') {
        setState(
          () => erroGeral =
              "Você precisa de uma conta de administrador para entrar em uma equipe.",
        );
        return;
      }

      if (!mounted) return;

      //modo equipe: rota pro código de acesso (sem salvar a sessão)
      if (widget.modoEquipe) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EntrarCodigo(
              usuarioId: idUsuario,
              nomeUsuario: resultado['nome'] as String? ?? '',
            ),
          ),
        );
        return;
      }

      //salva quem logou
      Sessao.definir(
        idUsuarioLogado: idUsuario,
        nomeLogado: resultado['nome'] as String? ?? '',
        emailLogado: emailController.text.trim(),
        tipoUsuarioLogado: tipoUsuario ?? 'Cliente',
      );

      //rota: administrador → início do admin, cliente → início do cliente
      Navigator.pushNamed(
        context,
        tipoUsuario == 'Administrador' ? '/inicioAdm' : '/home_cliente',
      );
    } on ApiException catch (e) {
      setState(() => erroGeral = e.mensagem);
    } finally {
      if (mounted) setState(() => entrando = false);
    }
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
                      Image.asset(
                        "assets/images/balaologo.png",
                        width: 46,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        "assets/images/escritalogo.png",
                        height: 32,
                        fit: BoxFit.contain,
                      ),
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
                        Text(
                          widget.modoEquipe
                              ? "Entre com a conta de administrador para continuar"
                              : "Acesse sua conta para continuar",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontFamily: "Poppins",
                          ),
                        ),

                        //aviso do modo equipe
                        if (widget.modoEquipe) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Cores.tag,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Você está entrando pra depois usar o código de acesso de uma equipe existente.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _rotulo("E-mail"),
                        const SizedBox(height: 8),
                        _campo(
                          controller: emailController,
                          hint: "seuemail@exemplo.com",
                          teclado: TextInputType.emailAddress,
                          //validação: email vazio ou sem @ e ponto
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
                              senhaVisivel
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => senhaVisivel = !senhaVisivel),
                          ),
                          //validação: senha vazia
                          validador: (v) => (v == null || v.isEmpty)
                              ? "Informe sua senha."
                              : null,
                        ),

                        const SizedBox(height: 10),
                        //rota pro "esqueci minha senha"
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EsqueciSenha(),
                              ),
                            ),
                            child: const Text(
                              "Esqueci minha senha",
                              style: TextStyle(
                                color: Cores.roxo,
                                fontSize: 12.5,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ),

                        if (erroGeral != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            erroGeral!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        //botão Entrar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: entrando ? null : entrar,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Cores.roxoBotao,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: entrando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Entrar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "PoppinsBold",
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //rota pro cadastro
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Cadastro(modoEquipe: widget.modoEquipe),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: "Não tem conta? ",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontFamily: "Poppins",
                        ),
                        children: [
                          TextSpan(
                            text: "Cadastre-se",
                            style: const TextStyle(
                              color: Cores.roxo,
                              fontFamily: "PoppinsSemi",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  //rota pro "entrar numa equipe" (some no modo equipe)
                  if (!widget.modoEquipe) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EntrarEquipe()),
                      ),
                      child: const Text(
                        "Já faz parte de uma equipe? Entrar com código",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //texto em cima de cada campo
  Widget _rotulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontFamily: "Poppins",
      ),
    );
  }

  //campo de texto padrão da tela
  Widget _campo({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validador,
    TextInputType? teclado,
    bool oculto = false,
    Widget? sufixo,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      validator: validador,
      style: const TextStyle(color: Colors.white, fontFamily: "Poppins"),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 13,
          fontFamily: "Poppins",
        ),
        filled: true,
        fillColor: Cores.campo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: sufixo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Cores.campoFoco, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
          fontFamily: "Poppins",
        ),
      ),
    );
  }
}
