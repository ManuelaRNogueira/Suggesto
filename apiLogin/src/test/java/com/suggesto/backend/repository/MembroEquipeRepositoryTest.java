package com.suggesto.backend.repository;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.MembroEquipe;
import com.suggesto.backend.model.Usuario;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;

// Roda sem a transação que o @DataJpaTest abre sozinho, porque o controller
// chama o delete fora de transação — é assim que o erro 500 aparecia.
@DataJpaTest
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class MembroEquipeRepositoryTest {

    @Autowired
    private MembroEquipeRepository membroEquipeRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    // Sem transação nada é desfeito sozinho; limpa pra não sujar os outros testes.
    @AfterEach
    void limpar() {
        membroEquipeRepository.deleteAll();
        estabelecimentoRepository.deleteAll();
        usuarioRepository.deleteAll();
    }

    @Test
    void removeMembroDaEquipeSemTransacaoAberta() {
        Usuario u = new Usuario();
        u.setUsername("membro_equipe_teste");
        u = usuarioRepository.save(u);

        Estabelecimento e = new Estabelecimento();
        e.setNome("Bar");
        e.setCnpj("11.111.111/0001-11");
        e.setCategoria("bar");
        e.setIdGerente(1L);
        e.setCep("11111-111");
        e.setEstado("SP");
        e.setCidade("Campinas");
        e.setBairro("Centro");
        e.setRua("Rua X");
        e.setNumero("10");
        e = estabelecimentoRepository.save(e);

        MembroEquipe m = new MembroEquipe();
        m.setUsuario(u);
        m.setEstabelecimento(e);
        membroEquipeRepository.save(m);

        membroEquipeRepository.deleteByUsuario_IdAndEstabelecimento_IdEstabelecimento(u.getId(), e.getIdEstabelecimento());

        assertThat(membroEquipeRepository
                .existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(u.getId(), e.getIdEstabelecimento())).isFalse();
    }
}
