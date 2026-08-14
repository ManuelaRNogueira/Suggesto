import 'package:flutter/material.dart';

class PerfilCliPage extends StatefulWidget {
  const PerfilCliPage({super.key});

  @override
  State<PerfilCliPage> createState() => _PerfilCliPageState();
}

class _PerfilCliPageState extends State<PerfilCliPage> {

  // Dados do usuário logado (mock)
  final String _nome = 'Manuela';
  final String _email = 'manuela@gmail.com';
  final String _nivel = 'Ouro';
  final String _fotoUrl =
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80';

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.bookmark_outlined, 'label': 'Locais Salvos', 'route': '/locais_salvos'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Minhas Sugestões', 'route': '/minhasSugestoes'},
    {'icon': Icons.bar_chart, 'label': 'Contribuição', 'route': null},
    {'icon': Icons.person_outline, 'label': 'Sobre Nós', 'route': '/sobrenos'},
    {'icon': Icons.person_outline, 'label': 'O Suggesto', 'route': '/suggesto'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12061E),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  _buildPerfilHeader(),
                  SizedBox(height: 32),
                  _buildMenuList(),
                  /*SizedBox(height: 32),
                  _buildBuscaUsuarios(),*/
                  SizedBox(height: 32),
                  _buildSairButton(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: barraNavegacao(),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildIconButton(Icons.notifications_outlined, onTap: () {}),
            SizedBox(width: 10),
            _buildIconButton(Icons.settings_outlined, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF1E0E32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF2A1A4A), width: 1),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildPerfilHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF9B59D0), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF9B59D0).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                  'assets/images/manuela.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Color(0xFF2A1A4A),
                  child: Icon(Icons.person, color: Colors.white38, size: 40),
                ),
              ),
            ),
          ),
          SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nome, style: TextStyle(
                color: const Color.fromARGB(207, 255, 255, 255),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'PoppinsBold',
              )),
              SizedBox(height: 2),
              Text(_email, style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                fontFamily: 'Poppins',
              )),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF3A1A6A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF9B59D0).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_nivel, style: TextStyle(
                      color: const Color.fromARGB(208, 255, 255, 255),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    )),
                    SizedBox(width: 5),
                    Text('🏅', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1E0E32),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFF2A1A4A), width: 1),
        ),
        child: Column(
          children: List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final isLast = index == _menuItems.length - 1;
            return Column(
              children: [
                _buildMenuItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  onTap: () {
                    if (item['route'] != null) {
                      Navigator.pushNamed(context, item['route']);
                    }
                  },
                ),
                if (!isLast)
                  Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 20, endIndent: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(
                color: const Color.fromARGB(199, 255, 255, 255),
                fontSize: 15,
                fontFamily: 'Poppins',
               /* fontWeight: FontWeight.w500,*/
              )),
            ),
            Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSairButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Sair da conta', style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontFamily: 'PoppinsSemi',
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }

  int paginaAtual = 3;
  Widget barraNavegacao() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF12061E),
        border: Border(top: BorderSide(color: Color(0xFF1E0E32), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 0);
                  Navigator.pushNamed(context, '/home_cliente');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_filled,
                      color: paginaAtual == 0 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Início",
                      style: TextStyle(
                        color: paginaAtual == 0 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 1);
                  Navigator.pushNamed(context, '/minhasSugestoes');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum,
                      color: paginaAtual == 1 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Minhas\nSugestões",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: paginaAtual == 1 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 2);
                  Navigator.pushNamed(context, '/loja');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: paginaAtual == 2 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Pontos",
                      style: TextStyle(
                        color: paginaAtual == 2 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() => paginaAtual = 3);
                  Navigator.pushNamed(context, '/perfil');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: paginaAtual == 3 ? Colors.white : Colors.white54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Perfil",
                      style: TextStyle(
                        color: paginaAtual == 3 ? Colors.white : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet de busca de usuários ───────────────────────────────────────────────
