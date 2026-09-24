package com.suggesto.backend.service;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.model.Visita;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.repository.VisitaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VisitaServiceTest {

    private static final long ID_USUARIO = 7L;
    private static final long ID_ESTAB = 3L;
    private static final String TOKEN = "tokencerto000000";

    @Mock
    private VisitaRepository visitaRepository;
    @Mock
    private UsuarioRepository usuarioRepository;
    @Mock
    private EstabelecimentoRepository estabelecimentoRepository;
    @Mock
    private AvaliacaoRepository avaliacaoRepository;

    @InjectMocks
    private VisitaService visitaService;

    private final Usuario usuario = new Usuario();
    private final Estabelecimento estab = new Estabelecimento();

    private void cenario() {
        usuario.setId(ID_USUARIO);
        estab.setIdEstabelecimento(ID_ESTAB);
        estab.setTokenCheckin(TOKEN);
        lenient().when(usuarioRepository.findById(ID_USUARIO)).thenReturn(Optional.of(usuario));
        lenient().when(estabelecimentoRepository.findById(ID_ESTAB)).thenReturn(Optional.of(estab));
        lenient().when(visitaRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    private Visita visita(long id, LocalDateTime quando) {
        Visita v = new Visita();
        v.setId(id);
        v.setUsuario(usuario);
        v.setEstabelecimento(estab);
        v.setMetodo(Visita.QR);
        v.setDataCheckin(quando);
        return v;
    }

    // ── Check-in por QR ──────────────────────────────────────────────────

    @Test
    void tokenCertoCriaVisitaPorQr() {
        cenario();
        Visita v = visitaService.checkinPorToken(ID_USUARIO, ID_ESTAB, TOKEN);
        assertThat(v.getMetodo()).isEqualTo(Visita.QR);
        assertThat(v.getUsuario()).isSameAs(usuario);
        assertThat(v.getEstabelecimento()).isSameAs(estab);
        assertThat(v.getDataCheckin()).isNotNull();
        verify(visitaRepository).save(v);
    }

    @Test
    void tokenErradoNaoCriaVisita() {
        cenario();
        assertThatThrownBy(() -> visitaService.checkinPorToken(ID_USUARIO, ID_ESTAB, "tokenerrado00000"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> visitaService.checkinPorToken(ID_USUARIO, ID_ESTAB, null))
                .isInstanceOf(IllegalArgumentException.class);
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void checkinRepetidoReaproveitaVisitaAberta() {
        cenario();
        Visita aberta = visita(9L, LocalDateTime.now().minusHours(2));
        when(visitaRepository.findByUsuario_IdAndEstabelecimento_IdEstabelecimentoAndDataCheckinAfter(
                eq(ID_USUARIO), eq(ID_ESTAB), any())).thenReturn(List.of(aberta));

        assertThat(visitaService.checkinPorToken(ID_USUARIO, ID_ESTAB, TOKEN)).isSameAs(aberta);
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void visitaAbertaJaUsadaNaoEReaproveitada() {
        cenario();
        Visita usada = visita(9L, LocalDateTime.now().minusHours(2));
        when(visitaRepository.findByUsuario_IdAndEstabelecimento_IdEstabelecimentoAndDataCheckinAfter(
                eq(ID_USUARIO), eq(ID_ESTAB), any())).thenReturn(List.of(usada));
        when(avaliacaoRepository.existsByVisita_Id(9L)).thenReturn(true);

        assertThat(visitaService.checkinPorToken(ID_USUARIO, ID_ESTAB, TOKEN)).isNotSameAs(usada);
        verify(visitaRepository).save(any());
    }

    // ── Check-in por localização ─────────────────────────────────────────

    @Test
    void localizacaoDentroDoRaioCriaVisitaPorLocalizacao() {
        cenario();
        estab.setLat(-22.5647);
        estab.setLng(-47.4017);
        // ~110 m ao norte
        Visita v = visitaService.checkinPorLocalizacao(ID_USUARIO, ID_ESTAB, -22.5637, -47.4017);
        assertThat(v.getMetodo()).isEqualTo(Visita.LOCALIZACAO);
        verify(visitaRepository).save(v);
    }

    @Test
    void localizacaoForaDoRaioDizADistancia() {
        cenario();
        estab.setLat(-22.5647);
        estab.setLng(-47.4017);
        // ~330 m ao norte
        assertThatThrownBy(() -> visitaService.checkinPorLocalizacao(ID_USUARIO, ID_ESTAB, -22.5617, -47.4017))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("cerca de 330 m");
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void estabelecimentoSemCoordenadasRecusaLocalizacao() {
        cenario();
        assertThatThrownBy(() -> visitaService.checkinPorLocalizacao(ID_USUARIO, ID_ESTAB, -22.5647, -47.4017))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("não tem a localização");
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void distanciaHaversine() {
        // 0,001° de latitude ≈ 111 m
        assertThat(VisitaService.distanciaEmMetros(0, 0, 0.001, 0)).isBetween(110.0, 112.0);
    }

    // ── Validar a visita na hora de avaliar ─────────────────────────────

    @Test
    void visitaValidaLiberaAvaliacao() {
        cenario();
        Visita v = visita(9L, LocalDateTime.now().minusHours(3));
        when(visitaRepository.findById(9L)).thenReturn(Optional.of(v));
        assertThat(visitaService.validarParaAvaliacao(9L, ID_USUARIO, ID_ESTAB)).isSameAs(v);
    }

    @Test
    void visitaExpiradaNaoLibera() {
        cenario();
        when(visitaRepository.findById(9L)).thenReturn(Optional.of(visita(9L, LocalDateTime.now().minusHours(25))));
        assertThatThrownBy(() -> visitaService.validarParaAvaliacao(9L, ID_USUARIO, ID_ESTAB))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("expirou");
    }

    @Test
    void visitaJaUsadaNaoLibera() {
        cenario();
        when(visitaRepository.findById(9L)).thenReturn(Optional.of(visita(9L, LocalDateTime.now().minusHours(1))));
        when(avaliacaoRepository.existsByVisita_Id(9L)).thenReturn(true);
        assertThatThrownBy(() -> visitaService.validarParaAvaliacao(9L, ID_USUARIO, ID_ESTAB))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("já foi usada");
    }

    @Test
    void visitaDeOutroUsuarioOuOutroLocalNaoLibera() {
        cenario();
        when(visitaRepository.findById(9L)).thenReturn(Optional.of(visita(9L, LocalDateTime.now().minusHours(1))));
        assertThatThrownBy(() -> visitaService.validarParaAvaliacao(9L, 8L, ID_ESTAB))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> visitaService.validarParaAvaliacao(9L, ID_USUARIO, 4L))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void visitaInexistenteNaoLibera() {
        cenario();
        when(visitaRepository.findById(anyLong())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> visitaService.validarParaAvaliacao(99L, ID_USUARIO, ID_ESTAB))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
