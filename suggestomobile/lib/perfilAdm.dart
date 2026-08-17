import 'package:flutter/material.dart';
import 'cores.dart';
import 'sessao.dart';
import 'api.dart';

// Perfil do administrador/estabelecimento — endereço, contato, sobre e
// métricas vêm de GET /api/estabelecimentos/{id} (nota/avaliações incluídas
// via aplicarMediasDeAvaliacao no backend) + GET /api/admin/metricas
// (implementados, mesma fonte usada na tela Início do admin).
class PerfilAdm extends StatefulWidget {
  const PerfilAdm({super.key});

  @override
  State<PerfilAdm> createState() => _PerfilAdmState();
}

class _PerfilAdmState extends State<PerfilAdm> {
  int paginaAtual = 2;

  bool carregando = true;
  String? erro;

  Map<String, dynamic>? estabelecimento;
  int melhorias = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final idGerente = Sessao.idGerenteEfetivo;
      final estabs = await buscarEstabelecimentosAdmin(idGerente: idGerente);
      if (estabs.isEmpty) {
        setState(() => erro = 'Nenhum estabelecimento cadastrado.');
        return;
      }
      final idEstabelecimento = (estabs.first['id'] as num).toInt();
      final resultados = await Future.wait([
        buscarEstabelecimento(idEstabelecimento),
        buscarMetricasAdmin(idGerente: idGerente),
      ]);
      setState(() {
        estabelecimento = resultados[0] as Map<String, dynamic>;
        melhorias = ((resultados[1] as Map<String, dynamic>)['implementados'] as num?)?.toInt() ?? 0;
      });
    } on ApiException catch (e) {
      setState(() => erro = e.mensagem);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(child: _corpo()),
      bottomNavigationBar: _buildBarraNavegacao(),
    );
  }

  Widget _corpo() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: Cores.roxo));
    }
    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              TextButton(onPressed: _carregar, child: const Text('Tentar de novo', style: TextStyle(color: Cores.roxo, fontFamily: 'Poppins'))),
            ],
          ),
        ),
      );
    }

    final e = estabelecimento!;
    return RefreshIndicator(
      color: Cores.roxo,
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopoConfig(),
            const SizedBox(height: 12),
            _buildCabecalho(e),
            const SizedBox(height: 20),
            _buildCardContato(e),
            const SizedBox(height: 16),
            _buildCardSobre(e),
            const SizedBox(height: 16),
            _buildCardMetricas(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopoConfig() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Cores.cartao,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Cores.borda),
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(Map<String, dynamic> e) {
    final nome = (e['nome'] as String?) ?? 'Estabelecimento';
    final categoria = (e['categoria'] as String?) ?? '';
    final nota = (e['mediaAvaliacoes'] as num?)?.toDouble();
    final fotoUrl = urlFotoEstabelecimento(e['fotoPath'] as String?);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: fotoUrl != null
              ? Image.network(
                  fotoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _logoPlaceholder(),
                )
              : _logoPlaceholder(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'PoppinsSemi',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (categoria.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  categoria,
                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins'),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (nota != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Cores.tag,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Cores.roxo.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Cores.amarelo, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            nota.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar perfil ainda não está pronto.', style: TextStyle(fontFamily: 'Poppins'))),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Cores.roxoBotao,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Editar perfil',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.storefront, color: Colors.white38),
    );
  }

  Widget _buildCardContato(Map<String, dynamic> e) {
    final rua = (e['rua'] as String?) ?? '';
    final numero = (e['numero'] as String?) ?? '';
    final bairro = (e['bairro'] as String?) ?? '';
    final cidade = (e['cidade'] as String?) ?? '';
    final estado = (e['estado'] as String?) ?? '';
    final partesEndereco = <String>[
      if (rua.isNotEmpty) (numero.isNotEmpty ? '$rua, $numero' : rua),
      if (bairro.isNotEmpty) bairro,
      if (cidade.isNotEmpty) (estado.isNotEmpty ? '$cidade - $estado' : cidade),
    ];
    final endereco = partesEndereco.isNotEmpty ? partesEndereco.join(' - ') : 'Endereço não informado';

    final telefone = (e['telefone'] as String?)?.isNotEmpty == true ? e['telefone'] as String : 'Não informado';
    final email = (Sessao.email?.isNotEmpty == true) ? Sessao.email! : 'Não informado';
    final horario = (e['horarioFuncionamento'] as String?)?.isNotEmpty == true
        ? e['horarioFuncionamento'] as String
        : 'Não informado';

    return _card(
      titulo: null,
      filhos: [
        _linhaContato(Icons.location_on_outlined, endereco),
        _linhaContato(Icons.phone_outlined, telefone),
        _linhaContato(Icons.email_outlined, email),
        _linhaContato(Icons.schedule_outlined, horario, ultima: true),
      ],
    );
  }

  Widget _linhaContato(IconData icone, String texto, {bool ultima = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Cores.roxo, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSobre(Map<String, dynamic> e) {
    final sobre = (e['sobre'] as String?)?.isNotEmpty == true
        ? e['sobre'] as String
        : 'Nenhuma descrição cadastrada ainda.';

    return _card(
      titulo: 'Sobre',
      filhos: [
        Text(
          sobre,
          style: const TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Poppins', height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCardMetricas() {
    return _card(
      titulo: null,
      filhos: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Cores.verde, size: 22),
            const SizedBox(width: 12),
            Text(
              '$melhorias',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'PoppinsBold', fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Text(
              'melhorias',
              style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required String? titulo, required List<Widget> filhos}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null) ...[
            Text(
              titulo,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'PoppinsSemi', fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
          ],
          ...filhos,
        ],
      ),
    );
  }

  Widget _buildBarraNavegacao() {
    final abas = [
      _Aba('Início', Icons.home_filled, '/inicioAdm'),
      _Aba('Sugestões', Icons.forum, '/sugestoesAdm'),
      _Aba('Perfil', Icons.person, '/perfilAdm'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Cores.fundo,
        border: Border(top: BorderSide(color: Cores.cartao, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < abas.length; i++) _itemNavegacao(abas[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNavegacao(_Aba aba, int indice) {
    final ativo = paginaAtual == indice;
    return GestureDetector(
      onTap: () {
        setState(() => paginaAtual = indice);
        if (aba.rota != '/perfilAdm') Navigator.pushNamed(context, aba.rota);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(aba.icone, color: ativo ? Colors.white : Colors.white54),
          const SizedBox(height: 4),
          Text(
            aba.rotulo,
            style: TextStyle(
              color: ativo ? Colors.white : Colors.white54,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _Aba {
  final String rotulo;
  final IconData icone;
  final String rota;
  _Aba(this.rotulo, this.icone, this.rota);
}
