import 'package:flutter/material.dart';
import 'package:suggestomobile/buscarEstabelecimento.dart';
import 'package:suggestomobile/cadastro.dart';
import 'package:suggestomobile/infoLocal.dart';
import 'package:suggestomobile/inicialcli.dart';
//import 'package:suggestomobile/inicialcli.dart';
import 'package:suggestomobile/inicio.dart';
import 'package:suggestomobile/inicioAdm.dart';
import 'package:suggestomobile/locaisSalvos.dart';
import 'package:suggestomobile/login.dart';
import 'package:suggestomobile/lojaPontos.dart';
import 'package:suggestomobile/minhasSugestoes.dart';
import 'package:suggestomobile/perfilAdm.dart';
import 'package:suggestomobile/perfilClie.dart';
import 'package:suggestomobile/sobrenos.dart';
import 'package:suggestomobile/sugerir.dart';
import 'package:suggestomobile/suggesto.dart';
import 'package:suggestomobile/sugestoesAdm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suggesto',
      theme: ThemeData(
        
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),

      initialRoute: '/login', 
      
      routes: {
        '/login': (context) => Login(),
        '/cadastro': (context) => Cadastro(),
        '/inicio': (context) => Inicio(),
        '/home_cliente': (context) => HomePage(),
        '/inicioAdm': (context) => InicioAdm(),
        '/sugestoesAdm': (context) => SugestoesAdm(),
        '/perfil': (context) => PerfilCliPage(),
        '/perfilAdm': (context) => const PerfilAdm(),
        '/sugerir': (context) => SugerirPage(),
        '/locais_salvos': (context) => LocaisSalvosPage(),
        '/loja': (context) => LojasPontosPage(),
        '/info_local': (context) => InfoLocalPage(local: {},),
        '/sobrenos': (context) => Sobrenos(),
        '/suggesto': (context) => Suggesto(),
        '/minhasSugestoes': (context) => MinhasSugestoes(),
      },
    );
  }
}

