package com.suggesto.backend.util;

import java.text.Normalizer;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// Normaliza texto livre digitado pelo usuário (hoje: cidade) para ficar
// consistente entre cadastros — mesmo sem forçar um <select> com todas as
// ~5.570 cidades do Brasil. Junta espaços duplicados e aplica capitalização
// de nome próprio, mantendo conectivos comuns em minúsculo.
public final class TextoUtil {

    private static final Set<String> CONECTIVOS = Set.of("de", "da", "do", "das", "dos", "e");

    private static final Set<String> UFS = Set.of(
            "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA",
            "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO");

    // Cidade seguida do estado, com ou sem separador: "Limeira - SP", "Limeira/SP",
    // "Limeira, SP" ou "Limeira SP".
    private static final Pattern SUFIXO_UF = Pattern.compile("^(.+?)\\s*(?:[-/,]\\s*|\\s)([A-Za-z]{2})$");

    private TextoUtil() {
    }

    // Compara texto livre ignorando acento, caixa e espaços extras — é assim que
    // a cidade do cliente casa com a do estabelecimento sem exigir digitação idêntica.
    public static boolean mesmoTexto(String a, String b) {
        String na = normalizarParaComparacao(a);
        return !na.isEmpty() && na.equals(normalizarParaComparacao(b));
    }

    // Tira acento, baixa a caixa e junta espaço duplicado — deixa o texto "cru"
    // só pra fins de comparação, sem mexer no que de fato fica salvo no banco.
    public static String normalizarParaComparacao(String texto) {
        if (texto == null) {
            return "";
        }
        String semAcento = Normalizer.normalize(texto.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
        return semAcento.replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
    }

    // Rede de segurança: o cadastro preenche a cidade pelo CEP, mas os dois
    // formulários deixam digitar à mão quando o CEP não é encontrado. Nesse caso
    // é comum vir a UF junto ("Limeira - SP"), o que quebrava a comparação por
    // igualdade e escondia a seção "Perto de você".
    private static String semUf(String cidade) {
        if (cidade == null) {
            return null;
        }
        String limpo = cidade.trim().replaceAll("\\s+", " ");
        Matcher m = SUFIXO_UF.matcher(limpo);
        if (m.matches() && UFS.contains(m.group(2).toUpperCase(Locale.ROOT))) {
            return m.group(1).trim();
        }
        return limpo;
    }

    // Forma canônica de gravar cidade: sem UF grudada e com capitalização de nome próprio.
    public static String normalizarCidade(String cidade) {
        return capitalizarNomeProprio(semUf(cidade));
    }

    // Compara cidades ignorando acento, caixa, espaços extras e a UF digitada junto.
    public static boolean mesmaCidade(String a, String b) {
        return mesmoTexto(semUf(a), semUf(b));
    }

    // Deixa cada palavra com a inicial maiúscula, tipo nome próprio, mas
    // mantém conectivos como "de", "da", "do" em minúsculo quando não são a
    // primeira palavra — assim "sao jose do rio preto" fica
    // "Sao Jose do Rio Preto", não "Sao Jose Do Rio Preto".
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
