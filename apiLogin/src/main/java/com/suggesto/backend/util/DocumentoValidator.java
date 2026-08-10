package com.suggesto.backend.util;

// Validação de CPF/CNPJ pelo algoritmo oficial de dígitos verificadores,
// não só contagem de caracteres — pega erros de digitação e sequências
// óbvias como "111.111.111-11".
public final class DocumentoValidator {

    private DocumentoValidator() {
    }

    public static boolean isCpfValido(String cpf) {
        String d = somenteDigitos(cpf);
        if (d.length() != 11 || todosIguais(d)) {
            return false;
        }
        int[] n = paraDigitos(d);

        int soma = 0;
        for (int i = 0; i < 9; i++) soma += n[i] * (10 - i);
        int dv1 = digitoVerificador(soma);
        if (dv1 != n[9]) return false;

        soma = 0;
        for (int i = 0; i < 10; i++) soma += n[i] * (11 - i);
        int dv2 = digitoVerificador(soma);
        return dv2 == n[10];
    }

    public static boolean isCnpjValido(String cnpj) {
        String d = somenteDigitos(cnpj);
        if (d.length() != 14 || todosIguais(d)) {
            return false;
        }
        int[] n = paraDigitos(d);

        int[] pesos1 = {5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int soma = 0;
        for (int i = 0; i < 12; i++) soma += n[i] * pesos1[i];
        int dv1 = digitoVerificador(soma);
        if (dv1 != n[12]) return false;

        int[] pesos2 = {6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        soma = 0;
        for (int i = 0; i < 13; i++) soma += n[i] * pesos2[i];
        int dv2 = digitoVerificador(soma);
        return dv2 == n[13];
    }

    private static int digitoVerificador(int soma) {
        int resto = soma % 11;
        return resto < 2 ? 0 : 11 - resto;
    }

    private static String somenteDigitos(String valor) {
        return valor == null ? "" : valor.replaceAll("\\D", "");
    }

    private static boolean todosIguais(String digitos) {
        return digitos.chars().distinct().count() == 1;
    }

    private static int[] paraDigitos(String digitos) {
        return digitos.chars().map(c -> c - '0').toArray();
    }
}
