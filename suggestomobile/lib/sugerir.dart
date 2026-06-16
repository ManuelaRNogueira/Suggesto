import 'package:flutter/material.dart';
import 'listaSugestoes.dart';

class SugerirPage extends StatefulWidget {
  final Map<String, dynamic>? local;

  const SugerirPage({super.key, this.local});

  @override
  State<SugerirPage> createState() => _SugerirPageState();
}

class _SugerirPageState extends State<SugerirPage> {
  final TextEditingController texto = TextEditingController();
  final int maxCaracteres = 500;
  String? categoriaSelecionada;
  bool enviado = false;

  final List<String> categorias = [
    'Atendimento',
    'Qualidade do produto',
    'Preço',
    'Estrutura',
    'Ambiente',
    'Higiene',
    'Cardápio',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  bool get podeEnviar =>
      texto.text.trim().isNotEmpty &&
      categoriaSelecionada != null &&
      !enviado;

  void _enviar() {
    if (!podeEnviar) return;
    setState(() => enviado = true);

    final local = widget.local ??
        {
          'nome': 'BigJack',
          'imagem':
              'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&q=80',
        };

    // Adiciona na lista global
    SugestoesStore.lista.insert(0, {
      "local": local['nome'] ?? 'Local',
      "imagem": local['imagem'] ?? '',
      "categoria": categoriaSelecionada!,
      "texto": texto.text.trim(),
      "status": "Em análise",
      "tempo": "agora mesmo",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0xFF2D5A27),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            SizedBox(width: 10),
            Text(
              'Sugestão enviada com sucesso!',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local ??
        {
          'nome': 'BigJack',
          'imagem':
              'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&q=80',
        };

    return Scaffold(
      backgroundColor: Color(0xFF12061E),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  _buildLocalInfo(local),
                  SizedBox(height: 20),
                  _buildTextArea(),
                  SizedBox(height: 24),
                  _buildCategoriasSection(),
                  SizedBox(height: 32),
                  _buildEnviarButton(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: barraNavegacao(),
    );
  }

  // APPBAR
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A0A2E),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Nova Sugestão',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PoppinsBold',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  // INFORMACOES DO LOCAL
  Widget _buildLocalInfo(Map<String, dynamic> local) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1E0E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3A1A6A), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: local['imagem'] != null
                ? Image.network(
                    local['imagem'],
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderLogo(),
                  )
                : _placeholderLogo(),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              local['nome'] ?? 'Local',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'PoppinsSemiBold',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Color(0xFF2A1A4A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.storefront, color: Colors.white38, size: 28),
    );
  }

  // ─── Text Area ─────────────────────────────────────────────────────
  Widget _buildTextArea() {
    final charCount = texto.text.length;
    final isNearLimit = charCount > (maxCaracteres * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E0E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: texto.text.isNotEmpty
              ? Color(0xFF9B59D0)
              : Color(0xFF3A1A6A),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: texto,
            maxLength: maxCaracteres,
            maxLines: 6,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Digite aqui sua sugestão.',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterText: '',
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$charCount/$maxCaracteres',
                  style: TextStyle(
                    color: isNearLimit
                        ? Color(0xFFFF6B6B)
                        : Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Categorias ────────────────────────────────────────────────────
  Widget _buildCategoriasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemCount: categorias.length,
          itemBuilder: (_, i) => _buildCategoriaChip(categorias[i]),
        ),
      ],
    );
  }

  Widget _buildCategoriaChip(String label) {
    final isSelected = categoriaSelecionada == label;

    return GestureDetector(
      onTap: () => setState(() {
        categoriaSelecionada = isSelected ? null : label;
      }),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color:
              isSelected ? Color(0xFF6B2FA0) : Color(0xFF2A1A4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(0xFF9B59D0)
                : Color(0xFF3A1A6A),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF9B59D0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  // ─── Botão Enviar ──────────────────────────────────────────────────
  Widget _buildEnviarButton() {
    return AnimatedOpacity(
      opacity: podeEnviar ? 1.0 : 0.45,
      duration: Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _enviar,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B2FBE), Color(0xFF9B59D0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: podeEnviar
                ? [
                    BoxShadow(
                      color: Color(0xFF9B59D0).withOpacity(0.4),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: enviado
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Enviar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PoppinsSemiBold',
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────
  int paginaAtual = 1;
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
                    Icon(Icons.home_filled,
                        color:
                            paginaAtual == 0 ? Colors.white : Colors.white54),
                    SizedBox(height: 4),
                    Text("Início",
                        style: TextStyle(
                            color: paginaAtual == 0
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 10)),
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
                    Icon(Icons.forum,
                        color:
                            paginaAtual == 1 ? Colors.white : Colors.white54),
                    SizedBox(height: 4),
                    Text("Minhas\nSugestões",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: paginaAtual == 1
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 10)),
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
                    Icon(Icons.monetization_on,
                        color:
                            paginaAtual == 2 ? Colors.white : Colors.white54),
                    SizedBox(height: 4),
                    Text("Pontos",
                        style: TextStyle(
                            color: paginaAtual == 2
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 10)),
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
                    Icon(Icons.person,
                        color:
                            paginaAtual == 3 ? Colors.white : Colors.white54),
                    SizedBox(height: 4),
                    Text("Perfil",
                        style: TextStyle(
                            color: paginaAtual == 3
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 10)),
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