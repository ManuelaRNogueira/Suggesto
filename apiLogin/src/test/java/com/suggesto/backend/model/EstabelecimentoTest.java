package com.suggesto.backend.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EstabelecimentoTest {

    private static Estabelecimento estab() {
        Estabelecimento e = new Estabelecimento();
        e.setNome("Bar");
        e.setCodigoAcesso("SGT-ABC123");
        e.setTokenCheckin("tok123abc");
        return e;
    }

    // O estabelecimento vai embutido em avaliação, recompensa e local salvo —
    // nenhum desses pode carregar o código da equipe nem o token do QR de check-in.
    @Test
    void segredosNaoSaemPorPadrao() throws Exception {
        Avaliacao a = new Avaliacao();
        a.setEstabelecimento(estab());
        String json = new ObjectMapper().writeValueAsString(a);
        assertThat(json).contains("Bar")
                .doesNotContain("SGT-ABC123", "codigoAcesso", "tok123abc", "tokenCheckin");
    }

    @Test
    void segredosSaemQuandoReveladosProDono() throws Exception {
        Estabelecimento e = estab();
        e.revelarDadosDoDono();
        assertThat(new ObjectMapper().writeValueAsString(e))
                .contains("\"codigoAcesso\":\"SGT-ABC123\"", "\"tokenCheckin\":\"tok123abc\"");
    }

    @Test
    void tokenGeradoEAleatorioESeguroPraUrl() {
        String t = Estabelecimento.gerarTokenCheckin();
        assertThat(t).hasSize(16).matches("[a-z0-9]+").isNotEqualTo(Estabelecimento.gerarTokenCheckin());
    }
}
