package com.suggesto.backend.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

// Roda contra um H2 em memória (o @DataJpaTest troca o MySQL sozinho).
@DataJpaTest
class MigracaoTokenCheckinTest {

    @Autowired
    private JdbcTemplate jdbc;

    private void inserir(long id, String token) {
        jdbc.update("INSERT INTO estabelecimento (id_estabelecimento, nome_estabelecimento, cnpj, categoria, id_gerente,"
                + " cep, estado, cidade, bairro, rua, numero, token_checkin)"
                + " VALUES (?, 'Bar', ?, 'bar', 1, '1', 'SP', 'c', 'b', 'r', '1', ?)", id, "cnpj" + id, token);
    }

    private List<String> tokens() {
        return jdbc.queryForList("SELECT token_checkin FROM estabelecimento ORDER BY id_estabelecimento", String.class);
    }

    @Test
    void preencheSoQuemNaoTemTokenCadaUmComOSeu() {
        inserir(1, null);
        inserir(2, null);
        inserir(3, "jaexistia0000000");

        new MigracaoTokenCheckin().preencher(jdbc);
        List<String> depois = tokens();

        assertThat(depois.get(0)).hasSize(16);
        assertThat(depois.get(1)).hasSize(16).isNotEqualTo(depois.get(0));
        assertThat(depois.get(2)).isEqualTo("jaexistia0000000");

        new MigracaoTokenCheckin().preencher(jdbc); // idempotente: não troca o que já tem
        assertThat(tokens()).isEqualTo(depois);
    }
}
