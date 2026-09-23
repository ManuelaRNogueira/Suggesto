package com.suggesto.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.LocalSalvoRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UsuarioControllerTest {

    @Mock
    private UsuarioRepository repository;
    @Mock
    private LocalSalvoRepository localSalvoRepository;
    @Mock
    private AvaliacaoRepository avaliacaoRepository;
    @Mock
    private ResgateRepository resgateRepository;

    @InjectMocks
    private UsuarioController controller;

    private static Usuario usuario() {
        Usuario u = new Usuario();
        u.setId(7L);
        u.setNome("Ana");
        u.setEmail("ana@x.com");
        u.setTelefone("19999999999");
        u.setCpf("12345678900");
        u.setCep("13480-000");
        return u;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> perfil(Long idSolicitante) {
        when(repository.findById(7L)).thenReturn(Optional.of(usuario()));
        return (Map<String, Object>) controller.buscarPorId(7L, idSolicitante).getBody();
    }

    @Test
    void donoDoPerfilVeDadosPessoais() {
        Map<String, Object> corpo = perfil(7L);
        assertThat(corpo).containsEntry("email", "ana@x.com").containsEntry("telefone", "19999999999");
    }

    @Test
    void outraPessoaNaoVeDadosPessoais() {
        Map<String, Object> corpo = perfil(8L);
        assertThat(corpo).containsEntry("nome", "Ana").doesNotContainKeys("email", "telefone", "cep");
    }

    @Test
    void semIdSolicitanteNaoVeDadosPessoais() {
        assertThat(perfil(null)).doesNotContainKeys("email", "telefone", "cep");
    }

    // O autor vai embutido em toda avaliação pública (/avaliacoes/estabelecimento/{id}).
    @Test
    void autorEmbutidoNaAvaliacaoNaoExpoeDadosPessoais() throws Exception {
        Avaliacao a = new Avaliacao();
        a.setUsuario(usuario());
        String json = new ObjectMapper().writeValueAsString(a);
        assertThat(json).contains("Ana").doesNotContain("ana@x.com", "19999999999", "12345678900", "13480-000");
    }
}
