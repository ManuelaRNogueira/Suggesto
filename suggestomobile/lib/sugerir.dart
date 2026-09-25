import 'package:flutter/material.dart';
import 'api.dart';
import 'categoriasPorRamo.dart';
import 'cores.dart';
import 'geoUtils.dart';
import 'sessao.dart';

class SugerirPage extends StatefulWidget {
  final Map<String, dynamic>? local;
  // Token do QR de check-in, quando a tela foi aberta pelo leitor.
  final String? tokenCheckin;

  const SugerirPage({super.key, this.local, this.tokenCheckin});

  @override
  State<SugerirPage> createState() => _SugerirPageState();
}

class _SugerirPageState extends State<SugerirPage> {
  final TextEditingController texto = TextEditingController();
  final int maxCaracteres = 500;
  int? idCategoriaSelecionada;
  // Mesmos três tipos do site (fazerSugestao.html): valor enviado → rótulo.
  static const tipos = {'sugestao': 'Sugestão', 'critica': 'Crítica', 'elogio': 'Elogio'};
  String tipoSelecionado = 'sugestao';
  int notaSelecionada = 0; // 0 = nenhuma estrela
  bool enviado = false;

  // Carregadas do backend em initState — filtradas pelo ramo do
  // estabelecimento usando o config central em categoriasPorRamo.dart.
  List<Map<String, dynamic>> categorias = [];
  bool carregandoCategorias = true;

  // Visita (check-in) que vai junto da sugestão e dá o selo "Visita confirmada".
  // Obrigatória: sem ela a API recusa a sugestão.
  int? idVisita;
  String? avisoVisita;
  bool fazendoCheckin = false;

  @override
  void initState() {
    super.initState();
    texto.addListener(() => setState(() {}));
    _carregarCategorias();
    if (widget.tokenCheckin != null && widget.tokenCheckin!.isNotEmpty) {
      _checkin(token: widget.tokenCheckin);
    }
  }

  // Com token confirma pelo QR; sem token pede o GPS.
  Future<void> _checkin({String? token}) async {
    final idEstabelecimento = (widget.local?['idEstabelecimento'] as num?)?.toInt();
    if (idEstabelecimento == null || Sessao.idUsuario == null) return;
    setState(() {
      fazendoCheckin = true;
      avisoVisita = null;
    });

    double? lat, lng;
    if (token == null) {
      final gps = await obterLocalizacaoParaCheckin();
      if (gps.posicao == null) {
        if (mounted) {
          setState(() {
            fazendoCheckin = false;
            avisoVisita = gps.erro;
          });
        }
        return;
      }
      lat = gps.posicao!.latitude;
      lng = gps.posicao!.longitude;
    }

    try {
      final visita = await fazerCheckin(
        idUsuario: Sessao.idUsuario!,
        idEstabelecimento: idEstabelecimento,
        token: token,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      setState(() => idVisita = (visita['idVisita'] as num?)?.toInt());
    } on ApiException catch (e) {
      if (mounted) setState(() => avisoVisita = e.mensagem);
    } finally {
      if (mounted) setState(() => fazendoCheckin = false);
    }
  }

  Future<void> _carregarCategorias() async {
    try {
      final tipoEstabelecimento = widget.local?['categoria'] as String?;
      final resultado = await buscarCategorias(tipoEstabelecimento);
      final todas = resultado.cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        categorias = filtrarCategoriasPorRamo(todas, tipoEstabelecimento);
        carregandoCategorias = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => carregandoCategorias = false);
    }
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  bool get podeEnviar =>
      texto.text.trim().isNotEmpty &&
      idCategoriaSelecionada != null &&
      notaSelecionada > 0 &&
      !enviado;

  Future<void> _enviar() async {
    if (!podeEnviar) return;

    final idEstabelecimento = (widget.local?['idEstabelecimento'] as num?)?.toInt();
    if (idEstabelecimento == null || Sessao.idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível identificar o estabelecimento.', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (idVisita == null) {
      _pedirCheckin('Confirme sua visita antes de enviar: leia o QR de check-in do local ou toque em "Estou aqui".');
      return;
    }

    setState(() => enviado = true);

    try {
      await criarAvaliacao(
        idUsuario: Sessao.idUsuario!,
        idEstabelecimento: idEstabelecimento,
        idCategoria: idCategoriaSelecionada!,
        tipo: tipoSelecionado,
        nota: notaSelecionada,
        comentario: texto.text.trim(),
        idVisita: idVisita,
      );

      if (!mounted) return;
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

      Future.delayed(Duration(milliseconds: 1400), () {
        if (mounted) Navigator.of(context).pop();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Todas as recusas de visita da API falam em "visita" (expirou, já usada...):
      // some o selo e volta o botão de check-in, com o motivo.
      setState(() => enviado = false);
      if (e.mensagem.toLowerCase().contains('visita')) {
        _pedirCheckin(e.mensagem);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem, style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Tira o selo e volta o botão "Estou aqui" com o motivo (o aviso fica no
  // topo da tela, por isso repete no SnackBar).
  void _pedirCheckin(String motivo) {
    setState(() {
      idVisita = null;
      avisoVisita = motivo;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(motivo, style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local ?? {'nome': 'Local'};

    return Scaffold(
      backgroundColor: Color(0xFF12061E),
      body: Column(
        children: [
          AppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  LocalInfo(local),
                  SizedBox(height: 12),
                  Visita(),
                  SizedBox(height: 20),
                  Tipos(),
                  SizedBox(height: 12),
                  AreaTexto(),
                  SizedBox(height: 20),
                  Estrelas(),
                  SizedBox(height: 24),
                  Categorias(),
                  SizedBox(height: 32),
                  botaoEnviar(),
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
  Widget AppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A0A2E),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
  Widget LocalInfo(Map<String, dynamic> local) {
    final fotoUrl = urlFotoEstabelecimento(local['fotoPath'] as String?);
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
            child: fotoUrl != null
                ? Image.network(
                    fotoUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Logo(),
                  )
                : Logo(),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              (local['nome'] as String?) ?? 'Local',
              style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'PoppinsSemiBold'),
            ),
          ),
        ],
      ),
    );
  }

  // CHECK-IN: selo quando confirmada; senão o aviso e o botão de GPS.
  Widget Visita() {
    if (idVisita != null) {
      return Row(children: [
        Icon(Icons.check_circle, color: Cores.verde, size: 18),
        SizedBox(width: 6),
        Text('Visita confirmada', style: TextStyle(color: Cores.verde, fontFamily: 'PoppinsSemiBold', fontSize: 13)),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avisoVisita != null) ...[
          Text(avisoVisita!, style: TextStyle(color: Cores.amarelo, fontFamily: 'Poppins', fontSize: 12.5)),
          SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: fazendoCheckin ? null : () => _checkin(),
          icon: fazendoCheckin
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Cores.verde))
              : Icon(Icons.location_on, color: Cores.verde, size: 18),
          label: Text('Estou aqui: confirmar visita',
              style: TextStyle(color: Cores.verde, fontFamily: 'PoppinsSemiBold', fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Cores.verde.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      ],
    );
  }

  Widget Logo() {
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

  // CAMPO DE TEXTO
  Widget AreaTexto() {
    final charCount = texto.text.length;
    final isNearLimit = charCount > (maxCaracteres * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E0E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: texto.text.isNotEmpty ? Color(0xFF9B59D0) : Color(0xFF3A1A6A),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: texto,
            maxLength: maxCaracteres,
            maxLines: 6,
            style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', height: 1.5),
            decoration: InputDecoration(
              hintText: 'Digite aqui sua sugestão.',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontFamily: 'Poppins'),
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
                    color: isNearLimit ? Color(0xFFFF6B6B) : Colors.white.withOpacity(0.3),
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

  // ESTRELAS
  Widget Estrelas() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Color(0xFF1E0E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notaSelecionada > 0 ? Color(0xFF9B59D0) : Color(0xFF3A1A6A),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sua avaliação',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins'),
          ),
          Row(
            children: List.generate(5, (i) {
              final estrela = i + 1;
              return GestureDetector(
                onTap: () => setState(() {
                  notaSelecionada = notaSelecionada == estrela ? 0 : estrela;
                }),
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    estrela <= notaSelecionada ? Icons.star : Icons.star_border,
                    color: estrela <= notaSelecionada ? Color(0xFFFFB800) : Colors.white30,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // CATEGORIAS
  Widget Categorias() {
    if (carregandoCategorias) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: Color(0xFF9B59D0)),
        ),
      );
    }

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
          itemBuilder: (_, i) => CategoriaCard(categorias[i]),
        ),
      ],
    );
  }

  Widget CategoriaCard(Map<String, dynamic> categoria) {
    final id = (categoria['idCategoria'] as num).toInt();
    final isSelected = idCategoriaSelecionada == id;
    return Opcao(categoria['nomeCategoria'] as String, isSelected, () => setState(() {
      idCategoriaSelecionada = isSelected ? null : id;
    }));
  }

  // TIPO (sugestão, crítica ou elogio) — sempre um marcado.
  Widget Tipos() {
    return Row(
      children: [
        for (final t in tipos.entries) ...[
          if (t.key != tipos.keys.first) SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 40,
              child: Opcao(t.value, tipoSelecionado == t.key, () => setState(() => tipoSelecionado = t.key)),
            ),
          ),
        ],
      ],
    );
  }

  Widget Opcao(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6B2FA0) : Color(0xFF2A1A4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF9B59D0) : Color(0xFF3A1A6A),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Color(0xFF9B59D0).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))]
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

  // BOTÃO ENVIAR
  Widget botaoEnviar() {
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
                ? [BoxShadow(color: Color(0xFF9B59D0).withOpacity(0.4), blurRadius: 16, offset: Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: enviado
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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

  // BOTTOM NAV
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
                onTap: () { setState(() => paginaAtual = 0); Navigator.pushNamed(context, '/home_cliente'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.home_filled, color: paginaAtual == 0 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Início", style: TextStyle(color: paginaAtual == 0 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 1); Navigator.pushNamed(context, '/minhasSugestoes'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.forum, color: paginaAtual == 1 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Minhas\nSugestões", textAlign: TextAlign.center, style: TextStyle(color: paginaAtual == 1 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 2); Navigator.pushNamed(context, '/loja'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.monetization_on, color: paginaAtual == 2 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Pontos", style: TextStyle(color: paginaAtual == 2 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
              GestureDetector(
                onTap: () { setState(() => paginaAtual = 3); Navigator.pushNamed(context, '/perfil'); },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person, color: paginaAtual == 3 ? Colors.white : Colors.white54),
                  SizedBox(height: 4),
                  Text("Perfil", style: TextStyle(color: paginaAtual == 3 ? Colors.white : Colors.white54, fontSize: 10)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}