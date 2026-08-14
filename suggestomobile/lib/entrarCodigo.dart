import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cores.dart';
import 'api.dart';
import 'login.dart';

// Código de acesso do estabelecimento — versão mobile de
// "Suggesto - Web/Web/entrarCodigo.html" / entrarCodigo.js. Só é alcançada
// depois de logar com uma conta de administrador (ver login.dart, modoEquipe).
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

  Future<void> _enviar() async {
    final codigo = codigoController.text.trim();
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
