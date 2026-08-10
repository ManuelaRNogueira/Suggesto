package com.suggesto.backend.config;

import com.suggesto.backend.model.Plano;
import com.suggesto.backend.repository.PlanoRepository;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// Fonte da verdade dos limites de plano: o que está escrito em planos.html.
// Roda em todo boot e é idempotente, então planos criados antes das colunas de
// limite existirem também são corrigidos aqui.
@Configuration
public class PlanoSeeder {

    @Bean
    public ApplicationRunner sincronizarPlanos(PlanoRepository planoRepository) {
        return args -> {
            //          nome            preço   estabs  feedbacks/mês  admins  relatórios exportação recompensas
            upsert(planoRepository, "Básico", 49.0, 1, 200, 1, false, false, false,
                    "Para pequenos negócios que estão começando a ouvir seus clientes.");
            upsert(planoRepository, "Pro", 119.0, 3, null, 3, true, true, true,
                    "Para negócios em crescimento que querem transformar dados em decisões.");
            upsert(planoRepository, "Empresarial", 299.0, null, null, null, true, true, true,
                    "Para redes e grupos com múltiplas unidades que precisam de controle total.");
        };
    }

    private void upsert(PlanoRepository repo, String nome, Double preco,
                        Integer limiteEstabelecimentos, Integer limiteFeedbacks, Integer limiteAdmins,
                        boolean relatorios, boolean exportacao, boolean recompensas, String descricao) {
        Plano plano = repo.findByNome(nome).orElseGet(Plano::new);
        plano.setNome(nome);
        plano.setDescricao(descricao);
        plano.setPreco(preco);
        plano.setLimiteEstabelecimentos(limiteEstabelecimentos);
        plano.setLimiteFeedbacksMes(limiteFeedbacks);
        plano.setLimiteAdmins(limiteAdmins);
        plano.setPermiteRelatorios(relatorios);
        plano.setPermiteExportacao(exportacao);
        plano.setPermiteRecompensas(recompensas);
        repo.save(plano);
    }
}
