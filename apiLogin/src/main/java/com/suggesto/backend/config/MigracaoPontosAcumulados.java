package com.suggesto.backend.config;

import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

// O nível passou a vir dos pontos acumulados (ver Usuario.pontosAcumulados), e
// a coluna nasce vazia nas contas antigas. Aqui ela é preenchida com o saldo
// atual + o que a pessoa já gastou em resgates. Só toca em quem ainda está
// nulo, então é idempotente e pode rodar em todo boot.
@Configuration
public class MigracaoPontosAcumulados {

    @Bean
    public ApplicationRunner migrarPontosAcumulados(JdbcTemplate jdbc) {
        return args -> preencher(jdbc);
    }

    public void preencher(JdbcTemplate jdbc) {
        int atualizados = jdbc.update(
                "UPDATE usuario SET pontos_acumulados = pontos + COALESCE(("
                        + "SELECT SUM(rc.custo_pontos) FROM resgate r "
                        + "JOIN recompensa rc ON rc.id = r.id_recompensa "
                        + "WHERE r.id_usuario = usuario.id_usuario), 0) "
                        + "WHERE pontos_acumulados IS NULL");
        if (atualizados > 0) {
            System.out.println("[migracao] pontos acumulados preenchidos para " + atualizados + " usuário(s).");
        }
    }
}
