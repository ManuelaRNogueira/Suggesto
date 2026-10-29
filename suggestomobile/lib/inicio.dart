import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart';

//tela de abertura com a logo
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {

  @override
  void initState() {
    super.initState();

    //depois de 4 segundos vai pro login
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(18, 6, 30, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              "assets/images/Logo.png",
              width: 250,
              height: 250,
            ),
          ],
        ),
      ),
    );
  }
}