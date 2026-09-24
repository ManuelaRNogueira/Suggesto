package com.suggesto.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.service.AvaliacaoService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EstabelecimentoControllerTest {

    @Mock
    private EstabelecimentoRepository repository;
    @Mock
    private AvaliacaoService avaliacaoService;

    @InjectMocks
    private EstabelecimentoController controller;

    private Estabelecimento estab() {
        Estabelecimento e = new Estabelecimento();
        e.setIdEstabelecimento(3L);
        e.setIdGerente(10L);
        e.setCodigoAcesso("SGT-ANTIGO");
        e.setTokenCheckin("tokenantigo00000");
        when(repository.findById(3L)).thenReturn(Optional.of(e));
        return e;
    }

    @Test
    void donoGeraCodigoNovoEOAntigoDeixaDeValer() {
        Estabelecimento e = estab();

        ResponseEntity<?> r = controller.gerarNovoCodigoAcesso(3L, 10L);

        assertThat(r.getStatusCode().value()).isEqualTo(200);
        assertThat(e.getCodigoAcesso()).startsWith("SGT-").isNotEqualTo("SGT-ANTIGO");
        assertThat(((Map<?, ?>) r.getBody()).get("codigoAcesso")).isEqualTo(e.getCodigoAcesso());
        verify(repository).save(e);
    }

    @Test
    void quemNaoEDonoNaoGeraCodigo() {
        Estabelecimento e = estab();

        ResponseEntity<?> r = controller.gerarNovoCodigoAcesso(3L, 11L);

        assertThat(r.getStatusCode().value()).isEqualTo(403);
        assertThat(e.getCodigoAcesso()).isEqualTo("SGT-ANTIGO");
        verify(repository, never()).save(any());
    }

    @Test
    void estabelecimentoInexistenteDa404() {
        when(repository.findById(99L)).thenReturn(Optional.empty());
        assertThat(controller.gerarNovoCodigoAcesso(99L, 10L).getStatusCode().value()).isEqualTo(404);
    }

    // ── Token do QR de check-in ───────────────────────────────────────────

    @Test
    void donoGeraTokenNovoEOAntigoDeixaDeValer() {
        Estabelecimento e = estab();

        ResponseEntity<?> r = controller.gerarNovoTokenCheckin(3L, 10L);

        assertThat(r.getStatusCode().value()).isEqualTo(200);
        assertThat(e.getTokenCheckin()).hasSize(16).isNotEqualTo("tokenantigo00000");
        assertThat(((Map<?, ?>) r.getBody()).get("tokenCheckin")).isEqualTo(e.getTokenCheckin());
        verify(repository).save(e);
    }

    @Test
    void quemNaoEDonoNaoGeraToken() {
        Estabelecimento e = estab();

        assertThat(controller.gerarNovoTokenCheckin(3L, 11L).getStatusCode().value()).isEqualTo(403);
        assertThat(e.getTokenCheckin()).isEqualTo("tokenantigo00000");
        verify(repository, never()).save(any());
    }

    @Test
    void detalheSoMostraTokenProDono() throws Exception {
        estab();
        ObjectMapper json = new ObjectMapper();

        assertThat(json.writeValueAsString(controller.buscarPorId(3L, 11L).getBody())).doesNotContain("tokenantigo00000");
        assertThat(json.writeValueAsString(controller.buscarPorId(3L, null).getBody())).doesNotContain("tokenantigo00000");
        assertThat(json.writeValueAsString(controller.buscarPorId(3L, 10L).getBody())).contains("tokenantigo00000");
    }
}
