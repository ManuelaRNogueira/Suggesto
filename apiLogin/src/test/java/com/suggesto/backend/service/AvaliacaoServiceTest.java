package com.suggesto.backend.service;

import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
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

    @InjectMocks
    private AvaliacaoService avaliacaoService;

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
        assertThat(avaliacaoService.atualizarStatus(1L, "recusado", ID_GERENTE).getStatus()).isEqualTo("RECUSADO");
    }

    @Test
    void membroDaEquipeMudaStatus() {
        sugestaoPendente();
        when(membroEquipeRepository.existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(20L, ID_ESTAB)).thenReturn(true);
        assertThat(avaliacaoService.atualizarStatus(1L, "recusado", 20L).getStatus()).isEqualTo("RECUSADO");
    }

    @Test
    void quemNaoEDaEquipeNaoMudaStatusNemCreditaPontos() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "implementado", 99L))
                .isInstanceOf(SecurityException.class);
        verify(avaliacaoRepository, never()).save(any());
        verify(usuarioRepository, never()).creditarPontos(anyLong(), anyInt());
    }

    @Test
    void semIdAdminNaoMudaStatus() {
        sugestaoPendente();
        assertThatThrownBy(() -> avaliacaoService.atualizarStatus(1L, "recusado", null))
                .isInstanceOf(SecurityException.class);
        verify(avaliacaoRepository, never()).save(any());
    }
}
