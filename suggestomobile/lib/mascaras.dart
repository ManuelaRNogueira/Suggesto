import 'package:flutter/services.dart';

// Máscaras feitas à mão (o projeto não tem pacote de máscara nas
// dependências) — mesmo formato usado nos campos do site: telefone, CPF e CEP.

String _somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = _somenteDigitos(newValue.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7 && digitos.length == 11) buffer.write('-');
      if (i == 6 && digitos.length == 10) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = _somenteDigitos(newValue.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = _somenteDigitos(newValue.text);
    if (digitos.length > 8) digitos = digitos.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
