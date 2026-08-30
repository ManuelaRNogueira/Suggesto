package com.suggesto.backend.service;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Plano;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.MembroEquipeRepository;
import com.suggesto.backend.repository.PlanoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PlanoServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;
    @Mock
    private EstabelecimentoRepository estabelecimentoRepository;
    @Mock
    private AvaliacaoRepository avaliacaoRepository;
    @Mock
    private PlanoRepository planoRepository;
    @Mock
    private MembroEquipeRepository membroEquipeRepository;

    @InjectMocks
    private PlanoService planoService;

    private static Plano plano(String nome, Integer limiteEstab, Integer limiteAdmins) {
        Plano p = new Plano();
        p.setNome(nome);
        p.setLimiteEstabelecimentos(limiteEstab);
        p.setLimiteAdmins(limiteAdmins);
        return p;
    }

    private static Usuario dono(Long id) {
        Usuario u = new Usuario();
        u.setId(id);
        return u;
    }

    @Test
    void trocaComSucessoQuandoDentroDosLimites() {
        Usuario usuario = dono(10L);
        Plano pro = plano("Pro", 3, 3);

        when(usuarioRepository.findById(10L)).thenReturn(Optional.of(usuario));
        when(estabelecimentoRepository.existsByIdGerenteAndAtivo(10L, 1)).thenReturn(true);
        when(planoRepository.findByNome("Pro")).thenReturn(Optional.of(pro));
        when(estabelecimentoRepository.buscarPorGerenteAtivos(10L)).thenReturn(List.of(new Estabelecimento()));
        when(membroEquipeRepository.countByEstabelecimento_IdGerente(10L)).thenReturn(1L);

        Plano resultado = planoService.trocarPlano(10L, "Pro");

        assertThat(resultado.getNome()).isEqualTo("Pro");
        assertThat(usuario.getPlano()).isEqualTo(pro);
        verify(usuarioRepository).save(usuario);
    }

    @Test
    void recusaQuemNaoPossuiEstabelecimento() {
        Usuario membro = dono(20L);

        when(usuarioRepository.findById(20L)).thenReturn(Optional.of(membro));
        when(estabelecimentoRepository.existsByIdGerenteAndAtivo(20L, 1)).thenReturn(false);

        assertThatThrownBy(() -> planoService.trocarPlano(20L, "Pro"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("possui um estabelecimento");

        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void bloqueiaDowngradeComEstabelecimentosDemais() {
        Usuario usuario = dono(10L);
        Plano basico = plano("Básico", 1, 1);

        when(usuarioRepository.findById(10L)).thenReturn(Optional.of(usuario));
        when(estabelecimentoRepository.existsByIdGerenteAndAtivo(10L, 1)).thenReturn(true);
        when(planoRepository.findByNome("Básico")).thenReturn(Optional.of(basico));
        when(estabelecimentoRepository.buscarPorGerenteAtivos(10L))
                .thenReturn(List.of(new Estabelecimento(), new Estabelecimento(), new Estabelecimento()));

        assertThatThrownBy(() -> planoService.trocarPlano(10L, "Básico"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Remova 2");

        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void bloqueiaDowngradeComAdminsDemais() {
        Usuario usuario = dono(10L);
        Plano basico = plano("Básico", 1, 1);

        when(usuarioRepository.findById(10L)).thenReturn(Optional.of(usuario));
        when(estabelecimentoRepository.existsByIdGerenteAndAtivo(10L, 1)).thenReturn(true);
        when(planoRepository.findByNome("Básico")).thenReturn(Optional.of(basico));
        when(estabelecimentoRepository.buscarPorGerenteAtivos(10L)).thenReturn(List.of(new Estabelecimento()));
        when(membroEquipeRepository.countByEstabelecimento_IdGerente(10L)).thenReturn(2L);

        assertThatThrownBy(() -> planoService.trocarPlano(10L, "Básico"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("equipe");

        verify(usuarioRepository, never()).save(any());
    }

    @Test
    void recusaPlanoInexistente() {
        Usuario usuario = dono(10L);
        when(usuarioRepository.findById(10L)).thenReturn(Optional.of(usuario));
        when(estabelecimentoRepository.existsByIdGerenteAndAtivo(10L, 1)).thenReturn(true);
        when(planoRepository.findByNome("Inexistente")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> planoService.trocarPlano(10L, "Inexistente"))
                .isInstanceOf(IllegalArgumentException.class);

        verify(usuarioRepository, never()).save(any());
    }
}
