package com.suggesto.backend.util;

// Régua de níveis do cliente — espelha js/pontosNiveis.js do site.
// Os patamares batem com o prêmio de 500 pts por sugestão aceita:
// Bronze 0–2 aceitas, Prata 3–10, Ouro 11–30, Platina 31+.
public final class NivelUtil {

    public static final int MIN_PRATA = 1001;
    public static final int MIN_OURO = 5001;
    public static final int MIN_PLATINA = 15001;

    private NivelUtil() {
    }

    // Cartão fidelidade: olha quantos pontos a pessoa tem e diz em qual faixa
    // ela está, checando do topo (Platina) pra baixo até achar onde ela se encaixa.
    public static String idNivel(Integer pontos) {
        int p = pontos == null ? 0 : Math.max(0, pontos);
        if (p >= MIN_PLATINA) return "platina";
        if (p >= MIN_OURO) return "ouro";
        if (p >= MIN_PRATA) return "prata";
        return "bronze";
    }

    // Mesma faixa de idNivel, só que devolvendo o nome bonito pra mostrar na tela.
    public static String nomeNivel(Integer pontos) {
        return switch (idNivel(pontos)) {
            case "platina" -> "Platina";
            case "ouro" -> "Ouro";
            case "prata" -> "Prata";
            default -> "Bronze";
        };
    }

    // Peso usado para priorizar a fila de sugestões do administrador:
    // quanto maior o nível do autor, mais alto o post aparece.
    public static int prioridade(Integer pontos) {
        return switch (idNivel(pontos)) {
            case "platina" -> 4;
            case "ouro" -> 3;
            case "prata" -> 2;
            default -> 1;
        };
    }
}
