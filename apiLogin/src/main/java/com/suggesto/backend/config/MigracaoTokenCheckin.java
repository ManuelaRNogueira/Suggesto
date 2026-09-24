package com.suggesto.backend.config;

import com.suggesto.backend.model.Estabelecimento;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

// Estabelecimento novo já nasce com token de check-in (ver cadastrar em
// EstabelecimentoController); os que existiam antes da coluna ganham um aqui.
// Só toca em quem ainda está sem token, então é idempotente e pode rodar em todo boot.
@Configuration
public class MigracaoTokenCheckin {

    @Bean
    public ApplicationRunner migrarTokenCheckin(JdbcTemplate jdbc) {
        return args -> preencher(jdbc);
    }

    public void preencher(JdbcTemplate jdbc) {
        List<Long> semToken = jdbc.queryForList(
                "SELECT id_estabelecimento FROM estabelecimento WHERE token_checkin IS NULL", Long.class);
        for (Long id : semToken) {
            jdbc.update("UPDATE estabelecimento SET token_checkin = ? WHERE id_estabelecimento = ? AND token_checkin IS NULL",
                    Estabelecimento.gerarTokenCheckin(), id);
        }
        if (!semToken.isEmpty()) {
            System.out.println("[migracao] token de check-in gerado para " + semToken.size() + " estabelecimento(s).");
        }
    }
}
