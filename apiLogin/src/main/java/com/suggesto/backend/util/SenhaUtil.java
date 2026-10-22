package com.suggesto.backend.util;

import java.util.regex.Pattern;

// Regra de senha única do sistema, usada no cadastro e na redefinição de
// senha. O site (cadastro.js, cadastroAdm.js, redefinirSenha.js) repete a
// mesma regra só pra avisar antes de enviar; quem decide é este aqui.
// Vale só pra senha nova: contas antigas continuam entrando com a senha que têm.
public final class SenhaUtil {

    public static final int TAMANHO_MINIMO = 8;
    // O BCrypt só considera os primeiros 72 bytes; acima disso o resto seria ignorado.
    public static final int TAMANHO_MAXIMO = 64;

    private static final Pattern LETRA = Pattern.compile("\\p{L}");
    private static final Pattern NUMERO = Pattern.compile("\\d");
    private static final Pattern ESPECIAL = Pattern.compile("[^\\p{L}\\d\\s]");

    private SenhaUtil() {}

    // Devolve a mensagem de erro que vai pra tela, ou null se a senha serve.
    public static String validar(String senha) {
        if (senha == null || senha.isBlank()) {
            return "Digite uma senha.";
        }
        if (senha.length() < TAMANHO_MINIMO) {
            return "A senha deve ter pelo menos " + TAMANHO_MINIMO + " caracteres.";
        }
        if (senha.length() > TAMANHO_MAXIMO) {
            return "A senha deve ter no máximo " + TAMANHO_MAXIMO + " caracteres.";
        }
        if (!LETRA.matcher(senha).find() || !NUMERO.matcher(senha).find() || !ESPECIAL.matcher(senha).find()) {
            return "A senha deve ter pelo menos uma letra, um número e um caractere especial (ex: ! @ # $ %).";
        }
        return null;
    }
}
