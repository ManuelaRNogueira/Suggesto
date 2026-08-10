package com.suggesto.backend.config;

import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

// O status "Em análise" era redundante com "Pendente" — sugestões novas nasciam
// como "analise" e a classificação jogava os dois no mesmo balde. Agora só existe
// "pendente"; este runner normaliza as linhas antigas uma única vez (é idempotente,
// então pode rodar em todo boot sem efeito colateral).
@Configuration
public class MigracaoStatusSugestao {

    @Bean
    public ApplicationRunner migrarStatusEmAnalise(JdbcTemplate jdbc) {
        return args -> {
            int atualizadas = jdbc.update(
                    "UPDATE avaliacao SET status = 'pendente' "
                            + "WHERE LOWER(TRIM(status)) IN ('analise', 'em analise', 'em análise', 'pending')");
            if (atualizadas > 0) {
                System.out.println("[migracao] " + atualizadas + " sugestão(ões) movidas de 'Em análise' para 'Pendente'.");
            }
        };
    }
}
