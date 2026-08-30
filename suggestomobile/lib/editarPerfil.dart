import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'sessao.dart';
import 'cores.dart';
import 'recorteImagem.dart';

// Editar nome e foto de perfil — mesmos campos do modal "Editar perfil" no
// site (perfilCli.html: Nome editável, E-mail só leitura, foto com recorte).
class EditarPerfilPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const EditarPerfilPage({super.key, required this.usuario});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  late final TextEditingController _nomeController;
  Uint8List? _fotoBytes; // já recortada, pronta pra enviar
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: (widget.usuario['nome'] as String?) ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final XFile? arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (arquivo == null || !mounted) return;

    final bytesOriginais = await arquivo.readAsBytes();
    if (!mounted) return;

    // Deixa a pessoa escolher qual parte da foto vai aparecer antes de
    // seguir — mesma etapa do site (ver js/imagemCrop.js).
    final recortado = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecorteImagemPage(bytesOriginais: bytesOriginais, redondo: true),
      ),
    );
    if (recortado == null || !mounted) return;

    setState(() => _fotoBytes = recortado);
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'O nome não pode ficar vazio.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final atualizado = await atualizarUsuario(
        Sessao.idUsuario!,
        nome: nome,
        fotoBytes: _fotoBytes,
      );
      Sessao.nome = (atualizado['nome'] as String?) ?? nome;
      if (!mounted) return;
      Navigator.pop(context, atualizado);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _iniciaisAvatar() {
    return Container(
      color: Cores.cartao,
      alignment: Alignment.center,
      child: Text(
        _iniciais((widget.usuario['nome'] as String?) ?? ''),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 26,
          fontFamily: 'PoppinsBold',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrlAtual = urlFotoUsuario(widget.usuario['fotoUrl'] as String?);

    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        elevation: 0,
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontFamily: 'PoppinsSemi', color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _escolherFoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Cores.roxo, width: 2.5),
                        ),
                        child: ClipOval(
                          child: _fotoBytes != null
                              ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                              : (fotoUrlAtual != null
                                    ? Image.network(
                                        fotoUrlAtual,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _iniciaisAvatar(),
                                      )
                                    : _iniciaisAvatar()),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Cores.roxo,
                            border: Border.all(color: Cores.fundo, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Cores.campo,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Cores.campoFoco,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'E-mail',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Cores.campo.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (widget.usuario['email'] as String?) ?? '',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Cores.roxoBotao,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontFamily: 'PoppinsSemi',
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
