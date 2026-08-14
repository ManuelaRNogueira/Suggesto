import 'package:flutter/material.dart';
import 'cores.dart';
import 'login.dart';
import 'cadastro.dart';

// Explicação de como entrar numa equipe já existente — versão mobile de
// "Suggesto - Web/Web/entrarEquipe.html". Só direciona pro login ou cadastro
// em modo equipe; quem faz a validação do código é a tela seguinte
// (entrarCodigo.dart), depois de logado.
class EntrarEquipe extends StatelessWidget {
  const EntrarEquipe({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: Cores.cartao, shape: BoxShape.circle, border: Border.all(color: Cores.borda)),
                          child: const Icon(Icons.group_add_outlined, color: Cores.roxo, size: 32),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Entrar em uma equipe",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: "PoppinsBold",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Se você foi convidado por um estabelecimento pra fazer parte da equipe, "
                              "você vai precisar de uma conta de administrador e do código de acesso do estabelecimento.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins", height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Login(modoEquipe: true)),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Cores.roxoBotao,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Já tenho conta",
                              style: TextStyle(color: Colors.white, fontFamily: "PoppinsBold", fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Cadastro(modoEquipe: true)),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Cores.borda),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Ainda não tenho conta",
                              style: TextStyle(fontFamily: "PoppinsSemi", fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
