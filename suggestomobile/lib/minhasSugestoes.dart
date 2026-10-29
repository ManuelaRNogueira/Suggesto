import 'package:flutter/material.dart';
import 'api.dart';
import 'sessao.dart';
import 'formatacao.dart';
import 'statusSugestao.dart';

//tela "Minhas Sugestões" do cliente: lista das sugestões enviadas
class MinhasSugestoes extends StatefulWidget {
  const MinhasSugestoes({super.key});

  @override
  State<MinhasSugestoes> createState() => _MinhasSugestoesState();
}

class _MinhasSugestoesState extends State<MinhasSugestoes> {
  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> sugestoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  //busca as sugestões do usuário
  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final lista = (await buscarAvaliacoesUsuario(Sessao.idUsuario!)).cast<Map<String, dynamic>>();
      //ordena: mais nova primeiro
      lista.sort((a, b) {
        final dataA = DateTime.tryParse(a['dataAvaliacao'] as String? ?? '');
        final dataB = DateTime.tryParse(b['dataAvaliacao'] as String? ?? '');
        //sem data vai pro fim da lista
        if (dataA == null && dataB == null) return 0;
        if (dataA == null) return 1;
        if (dataB == null) return -1;
        return dataB.compareTo(dataA);
      });
      setState(() => sugestoes = lista);
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  //converte o status do banco (aceita, aprovado, resolvida...) pra
  //pendente, implementado ou recusado
  String _normalizarStatus(String? bruto) {
    final chave = (bruto ?? '').trim().toLowerCase();
    const aceitos = {
      'aceita', 'aceito', 'aprovada', 'aprovado',
      'resolvida', 'resolvido', 'implementado', 'implementada',
    };
    const recusados = {'recusada', 'recusado'};
    if (aceitos.contains(chave)) return 'implementado';
    if (recusados.contains(chave)) return 'recusado';
    return 'pendente';
  }

  //apagar: pede confirmação e remove do servidor e da lista
  Future<void> removerSugestao(int index) async {
    bool? remover = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF12061E),
          title: Text("Remover sugestão", style: TextStyle(color: Colors.white)),
          content: Text("Deseja remover esta sugestão?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Remover", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (remover != true) return;

    final id = (sugestoes[index]['idAvaliacao'] as num?)?.toInt();
    if (id == null || Sessao.idUsuario == null) return;

    try {
      await excluirAvaliacao(id, Sessao.idUsuario!);
      setState(() => sugestoes.removeAt(index));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem), backgroundColor: Colors.redAccent),
      );
    }
  }

  //cartão de uma sugestão
  Widget sugestao({
    required String local,
    required String? imagem,
    required String categoria,
    required String texto,
    String? motivoRecusa,
    required String chaveStatus,
    required String tempo,
    required int nota,
    required int index,
  }) {
    return Container(
      width: 450,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(104, 47, 4, 116),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //foto do estabelecimento
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imagem != null && imagem.isNotEmpty
                ? Image.network(
                    imagem,
                    width: 95,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImagem(),
                  )
                : _placeholderImagem(),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //topo: nome + lixeira (se pendente) ou status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            local,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "PoppinsSemi",
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(80, 101, 26, 177),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria,
                              style: TextStyle(
                                color: Color.fromARGB(255, 147, 100, 236),
                                fontSize: 12,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => removerSugestao(index),
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        ),
                        SizedBox(height: 8),
                        pillStatus(chaveStatus),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 10),

                //estrelas da nota
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < nota ? Icons.star : Icons.star_border,
                      color: i < nota ? Color(0xFFFFB800) : Colors.white24,
                      size: 16,
                    );
                  }),
                ),

                SizedBox(height: 10),

                Text(
                  texto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color.fromARGB(190, 255, 255, 255),
                    fontSize: 13,
                    fontFamily: "Poppins",
                  ),
                ),

                //motivo da recusa (o estabelecimento é obrigado a dizer)
                if (motivoRecusa != null && motivoRecusa.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Motivo da recusa",
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: "PoppinsSemi"),
                        ),
                        SizedBox(height: 4),
                        Text(
                          motivoRecusa,
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: "Poppins"),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 15),

                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white54, size: 16),
                    SizedBox(width: 5),
                    Text(tempo, style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: "Poppins")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //ícone de loja no lugar da foto
  Widget _placeholderImagem() {
    return Container(
      width: 95,
      height: 140,
      decoration: BoxDecoration(
        color: Color(0xFF2A1A4A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(Icons.storefront, color: Colors.white38, size: 32),
    );
  }

  //barra de baixo: rotas pro Início, Sugestões, Loja e Perfil
  //aba marcada (1 = Sugestões)
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

  //carregando / erro / nenhuma sugestão / lista
  Widget _corpo() {
    if (carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF9B59D0))),
      );
    }
    if (erro != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _carregar,
              child: const Text('Tentar de novo', style: TextStyle(color: Color(0xFF9B59D0), fontFamily: 'Poppins')),
            ),
          ],
        ),
      );
    }
    if (sugestoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Você ainda não fez nenhuma sugestão.', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
        ),
      );
    }
    return Column(
      children: List.generate(sugestoes.length, (index) {
        final s = sugestoes[index];
        final estabelecimento = s['estabelecimento'] as Map<String, dynamic>?;
        final categoria = s['categoria'] as Map<String, dynamic>?;
        return Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: sugestao(
            index: index,
            local: (estabelecimento?['nome'] as String?) ?? 'Estabelecimento',
            imagem: urlFotoEstabelecimento(estabelecimento?['fotoPath'] as String?),
            categoria: (categoria?['nomeCategoria'] as String?) ?? 'Sem categoria',
            texto: (s['comentario'] as String?) ?? '',
            motivoRecusa: s['motivoRecusa'] as String?,
            chaveStatus: _normalizarStatus(s['status'] as String?),
            tempo: formatarData(s['dataAvaliacao'] as String?),
            nota: (s['nota'] as num?)?.toInt() ?? 0,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF12061E),
      //puxar pra baixo atualiza
      body: RefreshIndicator(
        color: const Color(0xFF9B59D0),
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 30),

                Text(
                  "Minhas Sugestões",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: "PoppinsSemi"),
                ),

                SizedBox(height: 40),

                _corpo(),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: barraNavegacao(),
    );
  }
}
