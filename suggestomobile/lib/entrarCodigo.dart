import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cores.dart';
import 'api.dart';
import 'login.dart';

//tela de digitar o código de acesso pra pedir pra entrar numa equipe
//só aparece depois do login de administrador em modo equipe
class EntrarCodigo extends StatefulWidget {
  final int usuarioId;
  final String nomeUsuario;

  const EntrarCodigo({super.key, required this.usuarioId, required this.nomeUsuario});

  @override
  State<EntrarCodigo> createState() => _EntrarCodigoState();
}

class _EntrarCodigoState extends State<EntrarCodigo> {
  final codigoController = TextEditingController();
  bool enviando = false;
  String? erro;
  String? nomeEstabelecimentoAprovado;

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  //envia o código pro servidor; deu certo → mostra a tela de sucesso
  Future<void> _enviar() async {
    final codigo = codigoController.text.trim();
    //validação: código vazio
    if (codigo.isEmpty) {
      setState(() => erro = "Informe o código de acesso.");
      return;
    }

    setState(() {
      erro = null;
      enviando = true;
    });

    try {
      final resultado = await entrarNaEquipe(usuarioId: widget.usuarioId, codigo: codigo);
      if (!mounted) return;
      setState(() {
        nomeEstabelecimentoAprovado = resultado['nomeEstabelecimento'] as String? ?? 'o estabelecimento';
      });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: SingleChildScrollView(
              child: nomeEstabelecimentoAprovado != null ? _telaSucesso() : _telaFormulario(),
            ),
          ),
        ),
      ),
    );
  }

  //campo do código + botão "Entrar na equipe"
  Widget _telaFormulario() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Olá, ${widget.nomeUsuario}",
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins"),
        ),
        const SizedBox(height: 8),
        const Text(
          "Código de acesso",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: "PoppinsBold", fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Digite o código que o administrador do estabelecimento te passou pra entrar na equipe.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins", height: 1.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: codigoController,
          maxLength: 10,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [UpperCaseTextFormatter()],
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "PoppinsSemi",
            fontSize: 18,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            counterText: "",
            hintText: "SGT-XXXXXX",
            hintStyle: const TextStyle(color: Colors.white24, fontFamily: "PoppinsSemi", fontSize: 18, letterSpacing: 2),
            filled: true,
            fillColor: Cores.campo,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Cores.campoFoco, width: 1.5),
            ),
          ),
        ),
        if (erro != null) ...[
          const SizedBox(height: 14),
          Text(erro!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: "Poppins")),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Cores.roxoBotao,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    "Entrar na equipe",
                    style: TextStyle(color: Colors.white, fontFamily: "PoppinsBold", fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }

  //pedido enviado: avisa que precisa esperar o dono aprovar
  Widget _telaSucesso() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: Cores.verdeFundo, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Cores.verde, size: 34),
        ),
        const SizedBox(height: 24),
        const Text(
          "Solicitação enviada!",
          style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: "PoppinsBold", fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "Aguarde a aprovação do administrador principal de $nomeEstabelecimentoAprovado. "
              "Depois de aprovado, é só entrar normalmente.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins", height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          //rota pro login (limpa as telas anteriores)
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Cores.roxoBotao,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Entendi",
              style: TextStyle(color: Colors.white, fontFamily: "PoppinsBold", fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

//deixa o que for digitado em maiúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
