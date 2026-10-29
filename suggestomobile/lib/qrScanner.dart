import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

//tela da câmera que lê o QR code e devolve o texto lido
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  //câmera de trás, só QR code, sem ler o mesmo código duas vezes
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _finalizado = false;

  //leu um QR: fecha a tela e devolve o conteúdo (só a primeira leitura vale)
  void _aoDetectar(BarcodeCapture captura) {
    if (_finalizado || captura.barcodes.isEmpty) return;

    final conteudo = captura.barcodes.first.rawValue?.trim();
    if (conteudo == null || conteudo.isEmpty) return;

    _finalizado = true;
    Navigator.of(context).pop(conteudo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
            //sem permissão ou câmera com problema: mostra aviso
            errorBuilder: (context, erro) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  erro.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Permita o acesso à câmera para escanear o QR Code.'
                      : 'Não foi possível abrir a câmera.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          Container(color: const Color(0x33000000)),
          //botão de fechar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0xB31A1924),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Fechar scanner',
                  ),
                ),
              ),
            ),
          ),
          //moldura roxa no meio (só visual)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF9B59D0), width: 3),
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Aponte a câmera para o QR Code do estabelecimento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
