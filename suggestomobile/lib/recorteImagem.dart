import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'cores.dart';

// Deixa a pessoa escolher qual parte da foto vai aparecer antes de usar —
// mesma ideia do recorte no site (ver js/imagemCrop.js) e no desktop
// (RecorteImagem.jsx), só que sem depender de nenhum plugin nativo: arrasta
// e dá zoom na imagem dentro de uma área fixa, e só o que estiver visível
// ali é capturado. "redondo" é só a moldura mostrada durante o ajuste — a
// saída sempre é um PNG quadrado (o círculo vem do jeito que o avatar já é
// exibido depois, com borda arredondada).
class RecorteImagemPage extends StatefulWidget {
  final Uint8List bytesOriginais;
  final bool redondo;

  const RecorteImagemPage({
    super.key,
    required this.bytesOriginais,
    this.redondo = false,
  });

  @override
  State<RecorteImagemPage> createState() => _RecorteImagemPageState();
}

class _RecorteImagemPageState extends State<RecorteImagemPage> {
  static const double _tamanhoArea = 300;

  final GlobalKey _boundaryKey = GlobalKey();
  bool _processando = false;

  // Em vez de calcular matematicamente qual pedaço da foto foi selecionado,
  // a gente tira uma espécie de "print" exato do que está aparecendo dentro
  // do quadradinho de recorte na tela — como uma captura de tela só daquela
  // área.
  Future<void> _confirmar() async {
    setState(() => _processando = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final imagem = await boundary.toImage(pixelRatio: 3);
      final byteData = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (!mounted) return;
      Navigator.pop(context, byteData?.buffer.asUint8List());
    } catch (_) {
      if (mounted) Navigator.pop(context, null);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        elevation: 0,
        title: const Text(
          'Ajustar foto',
          style: TextStyle(fontFamily: 'PoppinsSemi', color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Arraste e dê zoom para ajustar',
              style: TextStyle(color: Colors.white54, fontFamily: 'Poppins', fontSize: 13),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: ClipRect(
                        child: SizedBox(
                          width: _tamanhoArea,
                          height: _tamanhoArea,
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.memory(
                              widget.bytesOriginais,
                              fit: BoxFit.cover,
                              width: _tamanhoArea,
                              height: _tamanhoArea,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Moldura só de referência visual — não entra na foto final.
                    IgnorePointer(
                      child: Container(
                        width: _tamanhoArea,
                        height: _tamanhoArea,
                        decoration: BoxDecoration(
                          shape: widget.redondo
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          borderRadius: widget.redondo
                              ? null
                              : BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.85),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processando ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.roxo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _processando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Usar foto',
                          style: TextStyle(
                            fontFamily: 'PoppinsSemi',
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
