import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'cores.dart';
import 'formatacao.dart';
import 'sessao.dart';
import 'api.dart';
import 'cartoesStatusAdm.dart';
import 'solicitacoesEquipeAdm.dart';

// Versão mobile, só de leitura, da tela de detalhes de estabelecimento do
// desktop (Suggesto_DesktopReact/renderer/src/pages/DetalhesEstabelecimento.jsx)
// — sem a gestão de sugestões/edição que existe lá, já que isso já tem tela
// própria no mobile (Sugestões, com filtro por estabelecimento). O card de
// código da equipe e o resumo de status seguem o mesmo modelo já usado no
// Perfil do admin (perfilAdm.dart) e na tela Início (cartoesStatusAdm.dart),
// só que filtrados pra este estabelecimento específico.
// `estabelecimento` é o mesmo Map de GET /api/estabelecimentos/{id} (mais
// id/ativo/codigoAcesso/souDono, já mesclados pela lista) — sem chamada
// extra pra esses dados. Só as métricas de status são buscadas aqui.
class DetalhesEstabelecimentoAdm extends StatefulWidget {
  final Map<String, dynamic> estabelecimento;

  const DetalhesEstabelecimentoAdm({super.key, required this.estabelecimento});

  @override
  State<DetalhesEstabelecimentoAdm> createState() =>
      _DetalhesEstabelecimentoAdmState();
}

class _DetalhesEstabelecimentoAdmState
    extends State<DetalhesEstabelecimentoAdm> {
  bool carregandoMetricas = true;
  Map<String, dynamic>? metricas;
  bool codigoCopiado = false;

  late String? _tokenCheckin =
      widget.estabelecimento['tokenCheckin'] as String?;
  bool _gerandoNovoQr = false;

  @override
  void initState() {
    super.initState();
    _carregarMetricas();
  }

  Future<void> _carregarMetricas() async {
    final id = (widget.estabelecimento['id'] as num?)?.toInt();
    if (id == null) {
      setState(() => carregandoMetricas = false);
      return;
    }
    try {
      final m = await buscarMetricasAdmin(
        idGerente: Sessao.idUsuario,
        idEstabelecimento: id,
      );
      if (mounted) setState(() => metricas = m);
    } on ApiException {
      // Sem métricas não impede ver o resto da tela — o resto já veio pronto.
    } finally {
      if (mounted) setState(() => carregandoMetricas = false);
    }
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    setState(() => codigoCopiado = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => codigoCopiado = false);
    });
  }

  // Mesmo aviso do desktop: QRs já impressos param de confirmar visita na
  // hora que um novo token é gerado.
  Future<void> _confirmarGerarNovoQr(int idEstabelecimento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.cartao,
        title: const Text(
          'Gerar novo QR?',
          style: TextStyle(color: Colors.white, fontFamily: 'PoppinsSemi'),
        ),
        content: const Text(
          'Os QRs já impressos param de confirmar visitas na hora. Você vai precisar imprimir e trocar todos.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Gerar novo QR',
              style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'PoppinsSemi',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final idGerente = Sessao.idUsuario;
    if (idGerente == null) return;
    setState(() => _gerandoNovoQr = true);
    try {
      final resultado = await gerarNovoTokenCheckin(
        idEstabelecimento,
        idSolicitante: idGerente,
      );
      if (!mounted) return;
      setState(() => _tokenCheckin = resultado['tokenCheckin'] as String?);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _gerandoNovoQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.estabelecimento;
    final nome = (e['nome'] as String?) ?? 'Estabelecimento';
    final categoria = (e['categoria'] as String?) ?? '';
    final fotoUrl = urlFotoEstabelecimento(e['fotoPath'] as String?);
    final endereco = formatarEndereco(e);
    final telefone = (e['telefone'] as String?)?.trim();
    final horario = (e['horarioFuncionamento'] as String?)?.trim();
    final sobre = (e['sobre'] as String?)?.trim();
    final nota = (e['mediaAvaliacoes'] as num?)?.toDouble();
    final ativo = e['ativo'] as bool?;
    final codigoEquipe = e['codigoAcesso'] as String?;
    final souDono = e['souDono'] as bool? ?? false;
    final idEstabelecimento = (e['id'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopoVoltar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: fotoUrl != null
                            ? Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderFoto(),
                              )
                            : _placeholderFoto(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (categoria.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Cores.tag,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria,
                              style: const TextStyle(
                                color: Cores.roxo,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (nota != null && nota > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Cores.verdeFundo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Cores.amarelo,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  nota.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'PoppinsSemi',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (ativo == false) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Inativo',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'PoppinsBold',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _linhaInfo(Icons.location_on_outlined, endereco),
                    if (telefone != null && telefone.isNotEmpty)
                      _linhaInfo(Icons.phone_outlined, telefone),
                    if (horario != null && horario.isNotEmpty)
                      _linhaInfo(Icons.schedule_outlined, horario),
                    if (sobre != null && sobre.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _cardSobre(sobre),
                    ],
                    if (souDono &&
                        codigoEquipe != null &&
                        codigoEquipe.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _cardCodigoEquipe(codigoEquipe),
                    ],
                    if (souDono && idEstabelecimento != null) ...[
                      const SizedBox(height: 16),
                      _cardQrCheckin(idEstabelecimento),
                    ],
                    if (souDono && idEstabelecimento != null) ...[
                      const SizedBox(height: 16),
                      SolicitacoesEquipeAdm(
                        idEstabelecimento: idEstabelecimento,
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Sugestões deste estabelecimento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PoppinsSemi',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (carregandoMetricas)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: Cores.roxo),
                        ),
                      )
                    else
                      cartoesStatusAdm(
                        total:
                            (metricas?['totalSugestoes'] as num?)?.toInt() ?? 0,
                        pendentes:
                            (metricas?['pendentes'] as num?)?.toInt() ?? 0,
                        implementados:
                            (metricas?['implementados'] as num?)?.toInt() ?? 0,
                        recusados:
                            (metricas?['recusados'] as num?)?.toInt() ?? 0,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seta de voltar isolada, mesmo padrão de sobrenos.dart/suggesto.dart —
  // essa tela é um detalhe, sem Bottom Navigation.
  Widget _buildTopoVoltar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E0E32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A1A4A)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderFoto() {
    return Container(
      color: Cores.cartao,
      child: const Icon(Icons.storefront, color: Colors.white38, size: 48),
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Cores.roxo, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSobre(String sobre) {
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
          const Text(
            'Sobre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sobre,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Mesmo QR gerado no desktop (QrCheckin.jsx) — mesma URL, mesmo token, só
  // desenhado aqui em vez de lá. Por isso funciona exatamente igual: quem
  // lê com a câmera cai na mesma página de avaliação com a visita confirmada.
  Widget _cardQrCheckin(int idEstabelecimento) {
    final token = _tokenCheckin;
    final semCoordenadas =
        widget.estabelecimento['lat'] == null ||
        widget.estabelecimento['lng'] == null;

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
          const Text(
            'QR de check-in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Imprima e coloque nas mesas ou no balcão. Quem ler com a câmera do celular confirma que esteve aqui e já cai na página de avaliação.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
          if (semCoordenadas) ...[
            const SizedBox(height: 10),
            const Text(
              'Este estabelecimento ainda não tem localização no mapa, então o check-in pela localização do celular não vai funcionar. Por enquanto, só o QR confirma visitas.',
              style: TextStyle(
                color: Cores.amarelo,
                fontSize: 11,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: token != null && token.isNotEmpty
                  ? QrImageView(
                      data: urlCheckin(idEstabelecimento, token),
                      size: 180,
                      backgroundColor: Colors.white,
                    )
                  : const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(
                        child: Text(
                          'QR indisponível',
                          style: TextStyle(
                            color: Colors.black45,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _gerandoNovoQr
                  ? null
                  : () => _confirmarGerarNovoQr(idEstabelecimento),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Cores.borda),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _gerandoNovoQr
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Cores.roxo,
                      ),
                    )
                  : const Text(
                      'Gerar novo QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PoppinsSemi',
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Mesmo modelo do card de código da equipe em perfilAdm.dart.
  Widget _cardCodigoEquipe(String codigo) {
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
          const Text(
            'Código da equipe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'PoppinsSemi',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhe com quem vai administrar esse estabelecimento junto com você.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Cores.campo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'PoppinsSemi',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _copiarCodigo(codigo),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: codigoCopiado ? Cores.verdeFundo : Cores.roxoBotao,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    codigoCopiado ? Icons.check : Icons.copy,
                    color: codigoCopiado ? Cores.verde : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
