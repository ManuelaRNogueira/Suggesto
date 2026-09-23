package com.suggesto.backend.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EstabelecimentoTest {

    private static Estabelecimento estab() {
        Estabelecimento e = new Estabelecimento();
        e.setNome("Bar");
        e.setCodigoAcesso("SGT-ABC123");
        return e;
    }

    // O estabelecimento vai embutido em avaliação, recompensa e local salvo —
    // nenhum desses pode carregar o código que dá acesso à equipe.
    @Test
    void codigoNaoSaiPorPadrao() throws Exception {
        Avaliacao a = new Avaliacao();
        a.setEstabelecimento(estab());
        String json = new ObjectMapper().writeValueAsString(a);
        assertThat(json).contains("Bar").doesNotContain("SGT-ABC123", "codigoAcesso");
    }

    @Test
    void codigoSaiQuandoReveladoProDono() throws Exception {
        Estabelecimento e = estab();
        e.revelarCodigoAcesso();
        assertThat(new ObjectMapper().writeValueAsString(e)).contains("\"codigoAcesso\":\"SGT-ABC123\"");
    }
}
