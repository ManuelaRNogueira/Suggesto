package com.suggesto.backend.service;

import com.suggesto.backend.dto.AvaliacaoRequestDTO;
import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.model.Visita;
import com.suggesto.backend.repository.CategoriaRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.MembroEquipeRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AvaliacaoServiceTest {

    private static final long ID_ESTAB = 3L;
    private static final long ID_GERENTE = 10L;

    @Mock
    private AvaliacaoRepository avaliacaoRepository;
    @Mock
    private MembroEquipeRepository membroEquipeRepository;
    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private EstabelecimentoRepository estabelecimentoRepository;
    @Mock
    private CategoriaRepository categoriaRepository;
    @Mock
    private PlanoService planoService;
    @Mock
    private VisitaService visitaService;

    @InjectMocks
    private AvaliacaoService avaliacaoService;

    private static final String MOTIVO = "Já temos esse prato no cardápio de almoço.";

    private Avaliacao sugestao(String status) {
        Avaliacao a = sugestaoPendente();
        a.setStatus(status);
        return a;
    }

    private Avaliacao sugestaoPendente() {
        Estabelecimento estab = new Estabelecimento();
        estab.setIdEstabelecimento(ID_ESTAB);
        estab.setIdGerente(ID_GERENTE);
        Usuario autor = new Usuario();
        autor.setId(50L);
        Avaliacao a = new Avaliacao();
        a.setIdAvaliacao(1L);
        a.setStatus("pendente");
        a.setEstabelecimento(estab);
        a.setUsuario(autor);
        when(avaliacaoRepository.findById(1L)).thenReturn(Optional.of(a));
        lenient().when(avaliacaoRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        return a;
    }

    @Test
    void gerenteMudaStatus() {
        sugestaoPendente();
        assertThat(avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE, MOTIVO).getStatus()).isEqualTo("RECUSADO");
    }

    @Test
    void membroDaEquipeMudaStatus() {
        sugestaoPendente();
        when(membroEquipeRepository.existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(20L, ID_ESTAB)).thenReturn(true);
        assertThat(avaliacaoService.atualizarStatus(1L, "recusado", 20L, MOTIVO).getStatus()).isEqualTo("RECUSADO");
    }

    @Test
    void quemNaoEDaEquipeNaoMudaStatusNemCreditaPontos() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "implementado", 99L, null))
                .isInstanceOf(SecurityException.class);
        verify(avaliacaoRepository, never()).save(any());
        verify(usuarioRepository, never()).creditarPontos(anyLong(), anyInt());
    }

    @Test
    void semIdAdminNaoMudaStatus() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "recusado", null, MOTIVO))
                .isInstanceOf(SecurityException.class);
        verify(avaliacaoRepository, never()).save(any());
    }

    // ── Recusa com motivo ─────────────────────────────────────────────────

    @Test
    void recusarSemMotivoNaoMudaNada() {
        Avaliacao a = sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(a.getStatus()).isEqualTo("pendente");
        verify(avaliacaoRepository, never()).save(any());
    }

    @Test
    void recusarComMotivoCurtoNaoMudaNada() {
        Avaliacao a = sugestaoPendente();
        // 9 caracteres depois de tirar os espaços das pontas
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE, "   não dá.   "))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(a.getStatus()).isEqualTo("pendente");
        verify(avaliacaoRepository, never()).save(any());
    }

    @Test
    void recusarComMotivoGravaMotivoSemEspacosEDataDeDecisao() {
        sugestaoPendente();
        Avaliacao r = avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE, "  " + MOTIVO + "  ");
        assertThat(r.getStatus()).isEqualTo("RECUSADO");
        assertThat(r.getMotivoRecusa()).isEqualTo(MOTIVO);
        assertThat(r.getDataDecisao()).isNotNull();
    }

    @Test
    void implementarGravaDataDeDecisaoECreditaPontos() {
        sugestaoPendente();
        Avaliacao r = avaliacaoService.atualizarStatus(1L, "implementado", ID_GERENTE, null);
        assertThat(r.getStatus()).isEqualTo("IMPLEMENTADO");
        assertThat(r.getDataDecisao()).isNotNull();
        verify(usuarioRepository).creditarPontos(50L, 500);
    }

    @Test
    void reabrirRecusadaApagaMotivoEGravaDataDeDecisao() {
        Avaliacao a = sugestao("RECUSADO");
        a.setMotivoRecusa(MOTIVO);
        Avaliacao r = avaliacaoService.atualizarStatus(1L, "pendente", ID_GERENTE, null);
        assertThat(r.getStatus()).isEqualTo("PENDENTE");
        assertThat(r.getMotivoRecusa()).isNull();
        assertThat(r.getDataDecisao()).isNotNull();
    }

    @Test
    void implementadoEFinal() {
        sugestao("IMPLEMENTADO");
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE, MOTIVO))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "pendente", ID_GERENTE, null))
                .isInstanceOf(IllegalStateException.class);
        verify(avaliacaoRepository, never()).save(any());
    }

    @Test
    void recusadaNaoVaiDiretoParaImplementado() {
        sugestao("RECUSADO");
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "implementado", ID_GERENTE, null))
                .isInstanceOf(IllegalStateException.class);
        verify(usuarioRepository, never()).creditarPontos(anyLong(), anyInt());
    }

    @Test
    void pendenteNaoVaiParaPendente() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "pendente", ID_GERENTE, null))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void statusDesconhecidoERecusado() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "respondida", ID_GERENTE, null))
                .isInstanceOf(IllegalArgumentException.class);
        verify(avaliacaoRepository, never()).save(any());
    }

    // Os valores antigos gravados no banco ("aceita", "recusada"...) continuam valendo.
    @Test
    void statusAntigoRecusadaPodeSerReaberto() {
        sugestao("recusada");
        assertThat(avaliacaoService.atualizarStatus(1L, "pendente", ID_GERENTE, null).getStatus()).isEqualTo("PENDENTE");
    }

    // ── Enviar avaliação: visita obrigatória ─────────────────────────────

    private AvaliacaoRequestDTO novaAvaliacao(Long idVisita) {
        Usuario autor = new Usuario();
        autor.setId(50L);
        Estabelecimento estab = new Estabelecimento();
        estab.setIdEstabelecimento(ID_ESTAB);
        when(usuarioRepository.findById(50L)).thenReturn(Optional.of(autor));
        when(estabelecimentoRepository.findById(ID_ESTAB)).thenReturn(Optional.of(estab));
        when(categoriaRepository.findById(1L)).thenReturn(Optional.of(new Categoria()));

        AvaliacaoRequestDTO dto = new AvaliacaoRequestDTO();
        dto.setIdUsuario(50L);
        dto.setIdEstabelecimento(ID_ESTAB);
        dto.setIdCategoria(1L);
        dto.setNota(5);
        dto.setComentario("Muito bom");
        dto.setTipo("elogio");
        dto.setIdVisita(idVisita);
        return dto;
    }

    @Test
    void avaliacaoComVisitaValidaFicaVinculadaEComSelo() {
        AvaliacaoRequestDTO dto = novaAvaliacao(9L);
        Visita v = new Visita();
        v.setId(9L);
        v.setMetodo(Visita.QR);
        when(visitaService.validarParaAvaliacao(9L, 50L, ID_ESTAB)).thenReturn(v);

        avaliacaoService.registrarNovaAvaliacao(dto);

        org.mockito.ArgumentCaptor<Avaliacao> salva = org.mockito.ArgumentCaptor.forClass(Avaliacao.class);
        verify(avaliacaoRepository).save(salva.capture());
        assertThat(salva.getValue().getVisita()).isSameAs(v);
        assertThat(salva.getValue().getMetodoVisita()).isEqualTo(Visita.QR);
    }

    @Test
    void avaliacaoComVisitaInvalidaNaoESalva() {
        AvaliacaoRequestDTO dto = novaAvaliacao(9L);
        when(visitaService.validarParaAvaliacao(9L, 50L, ID_ESTAB))
                .thenThrow(new IllegalArgumentException("Sua visita expirou."));

        assertThatThrownBy(() -> avaliacaoService.registrarNovaAvaliacao(dto))
                .isInstanceOf(IllegalArgumentException.class);
        verify(avaliacaoRepository, never()).save(any());
    }

    @Test
    void avaliacaoSemVisitaERecusadaPedindoCheckin() {
        AvaliacaoRequestDTO dto = novaAvaliacao(null);

        assertThatThrownBy(() -> avaliacaoService.registrarNovaAvaliacao(dto))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("check-in");
        verify(avaliacaoRepository, never()).save(any());
    }

    // Sem o fallback pro convidado compartilhado: sem usuário, sem avaliação.
    @Test
    void avaliacaoSemUsuarioERecusada() {
        AvaliacaoRequestDTO dto = new AvaliacaoRequestDTO();
        dto.setIdEstabelecimento(ID_ESTAB);
        dto.setIdCategoria(1L);
        dto.setIdVisita(9L);

        assertThatThrownBy(() -> avaliacaoService.registrarNovaAvaliacao(dto))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("Entre na sua conta");
        verify(avaliacaoRepository, never()).save(any());
    }

    // O limite do plano só é conferido depois da visita.
    @Test
    void visitaInvalidaNemChegaNoLimiteDoPlano() {
        AvaliacaoRequestDTO dto = novaAvaliacao(9L);
        when(visitaService.validarParaAvaliacao(9L, 50L, ID_ESTAB))
                .thenThrow(new IllegalArgumentException("Sua visita expirou."));

        assertThatThrownBy(() -> avaliacaoService.registrarNovaAvaliacao(dto));
        verify(planoService, never()).validarNovoFeedback(any());
    }

    @Test
    void limiteDoPlanoContinuaValendoComVisitaValida() {
        AvaliacaoRequestDTO dto = novaAvaliacao(9L);
        when(visitaService.validarParaAvaliacao(9L, 50L, ID_ESTAB)).thenReturn(new Visita());
        org.mockito.Mockito.doThrow(new IllegalStateException("Limite do mês atingido."))
                .when(planoService).validarNovoFeedback(any());

        assertThatThrownBy(() -> avaliacaoService.registrarNovaAvaliacao(dto))
                .isInstanceOf(IllegalStateException.class);
        verify(avaliacaoRepository, never()).save(any());
    }
}
