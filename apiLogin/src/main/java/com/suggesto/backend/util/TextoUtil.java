package com.suggesto.backend.util;

import java.util.Locale;
import java.util.Set;

// Normaliza texto livre digitado pelo usuário (hoje: cidade) para ficar
// consistente entre cadastros — mesmo sem forçar um <select> com todas as
// ~5.570 cidades do Brasil. Junta espaços duplicados e aplica capitalização
// de nome próprio, mantendo conectivos comuns em minúsculo.
public final class TextoUtil {

    private static final Set<String> CONECTIVOS = Set.of("de", "da", "do", "das", "dos", "e");

    private TextoUtil() {
    }

    public static String capitalizarNomeProprio(String texto) {
        if (texto == null) {
            return null;
        }
        String limpo = texto.trim().replaceAll("\\s+", " ");
        if (limpo.isEmpty()) {
            return limpo;
        }

        String[] palavras = limpo.split(" ");
        StringBuilder resultado = new StringBuilder();
        for (int i = 0; i < palavras.length; i++) {
            String palavra = palavras[i].toLowerCase(Locale.forLanguageTag("pt-BR"));
            if (i > 0 && CONECTIVOS.contains(palavra)) {
                resultado.append(palavra);
            } else {
                resultado.append(Character.toUpperCase(palavra.charAt(0))).append(palavra.substring(1));
            }
            if (i < palavras.length - 1) {
                resultado.append(' ');
            }
        }
        return resultado.toString();
    }
}
