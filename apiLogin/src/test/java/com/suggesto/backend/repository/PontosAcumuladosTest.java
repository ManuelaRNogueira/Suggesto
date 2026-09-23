package com.suggesto.backend.repository;

import com.suggesto.backend.config.MigracaoPontosAcumulados;
import com.suggesto.backend.model.Usuario;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;

// Roda contra um H2 em memória (o @DataJpaTest troca o MySQL sozinho).
@DataJpaTest
class PontosAcumuladosTest {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private JdbcTemplate jdbc;

    private Long novoUsuario() {
        Usuario u = new Usuario();
        u.setUsername("ana");
        return usuarioRepository.save(u).getId();
    }

    @Test
    void resgatarGastaSaldoMasNaoDerrubaNivel() {
        Long id = novoUsuario();
        for (int i = 0; i < 3; i++) {
            usuarioRepository.creditarPontos(id, 500); // 3 sugestões aceitas = 1500 → Prata
        }
        usuarioRepository.debitarPontos(id, 1000);

        Usuario u = usuarioRepository.findById(id).orElseThrow();
        assertThat(u.getPontos()).isEqualTo(500);
        assertThat(u.getPontosAcumulados()).isEqualTo(1500);
        assertThat(u.getNivel()).isEqualTo("prata");
    }

    // Quem já existia antes da coluna: acumulado = saldo + tudo que já gastou em resgates.
    @Test
    void migracaoPreencheAcumuladoDeQuemJaExistia() {
        Long id = novoUsuario();
        jdbc.update("UPDATE usuario SET pontos = 200, pontos_acumulados = NULL WHERE id_usuario = ?", id);
        jdbc.update("INSERT INTO estabelecimento (id_estabelecimento, nome_estabelecimento, cnpj, categoria, id_gerente,"
                + " cep, estado, cidade, bairro, rua, numero) VALUES (1, 'Bar', '1', 'bar', 1, '1', 'SP', 'c', 'b', 'r', '1')");
        jdbc.update("INSERT INTO recompensa (id, nome, custo_pontos, id_estabelecimento) VALUES (1, 'Café', 1000, 1)");
        jdbc.update("INSERT INTO resgate (id_usuario, id_recompensa, data_resgate, codigo_cupom) VALUES (?, 1, CURRENT_TIMESTAMP, 'X')", id);

        new MigracaoPontosAcumulados().preencher(jdbc);
        new MigracaoPontosAcumulados().preencher(jdbc); // idempotente: não soma duas vezes

        assertThat(jdbc.queryForObject("SELECT pontos_acumulados FROM usuario WHERE id_usuario = ?", Integer.class, id))
                .isEqualTo(1200);
    }
}
