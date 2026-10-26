import 'package:flutter/material.dart';
import 'cores.dart';
import 'api.dart';

// "Esqueci minha senha" — porte de esqueciSenha.js/esqueciSenha.html do site.
// Só o pedido do link mora aqui: a redefinição de verdade (digitar a senha
// nova) continua acontecendo no site, porque é pra lá que o link do e-mail
// aponta (RecuperacaoSenhaService.solicitar monta
// "{siteUrl}/redefinir-senha.html?token=..."). Criar uma tela de redefinir
// aqui também exigiria o app saber abrir esse link direto nele (deep link),
// o que não existe hoje — então o fluxo simplesmente continua no navegador,
// igual já aconteceria em qualquer outro dispositivo.
class EsqueciSenha extends StatefulWidget {
  const EsqueciSenha({super.key});

  @override
  State<EsqueciSenha> createState() => _EsqueciSenhaState();
}

class _EsqueciSenhaState extends State<EsqueciSenha> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool enviando = false;
  String? erro;
  String? mensagemEnviada;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // A API sempre devolve a mesma mensagem genérica, exista o e-mail ou não —
  // a tela só repete o que ela mandar, sem tentar adivinhar nada.
  Future<void> _enviar() async {
    setState(() => erro = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => enviando = true);
    try {
      final resultado = await esqueciSenha(_emailController.text.trim());
      if (!mounted) return;
      setState(
        () => mensagemEnviada =
            (resultado['message'] as String?) ??
            'Se o e-mail estiver cadastrado, você receberá um link para redefinir a senha.',
      );
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => enviando = false);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopoVoltar(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Cores.cartao,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Cores.borda),
                  ),
                  child: mensagemEnviada != null
                      ? _buildSucesso()
                      : _buildFormulario(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopoVoltar() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Cores.cartao,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Cores.borda),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Esqueci minha senha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'PoppinsBold',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Digite seu e-mail e enviaremos um link pra redefinir sua senha.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'E-mail',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'seuemail@exemplo.com',
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: Cores.campo,
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
                  color: Cores.campoFoco,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
            validator: (v) {
              final valor = v?.trim() ?? '';
              if (valor.isEmpty) return 'Informe seu e-mail.';
              if (!valor.contains('@') || !valor.contains('.')) {
                return 'Digite um e-mail válido.';
              }
              return null;
            },
          ),
          if (erro != null) ...[
            const SizedBox(height: 14),
            Text(
              erro!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Cores.roxoBotao,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar link',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PoppinsBold',
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSucesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: Cores.roxo, size: 40),
        const SizedBox(height: 16),
        const Text(
          'Verifique seu e-mail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'PoppinsBold',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mensagemEnviada!,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'O link abre no navegador do celular — depois de criar a nova senha, volte aqui e entre normalmente.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Cores.borda),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Voltar para o login',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PoppinsSemi',
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
