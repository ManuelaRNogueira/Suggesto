package com.suggesto.backend.config;

import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.repository.CategoriaRepository;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

// Preenche o escopo (TODOS/FISICO/COMIDA) das categorias de sugestão, usado
// por CategoriaController pra filtrar por tipo de estabelecimento. Roda em
// todo boot e é idempotente, então corrige linhas que ficaram com escopo nulo
// (ex: criadas antes dessa coluna existir) sem precisar rodar SQL manual.
@Configuration
public class CategoriaEscopoSeeder {

    private static final Map<String, String> ESCOPOS = Map.of(
            "Atendimento", "TODOS",
            "Qualidade do produto", "TODOS",
            "Preço", "TODOS",
            "Estrutura", "FISICO",
            "Ambiente", "FISICO",
            "Higiene", "FISICO",
            "Cardápio", "COMIDA",
            "Outro", "TODOS"
    );

    @Bean
    public ApplicationRunner preencherEscopoCategorias(CategoriaRepository categoriaRepository) {
        return args -> {
            for (Categoria categoria : categoriaRepository.findAll()) {
                String escopo = ESCOPOS.get(categoria.getNomeCategoria());
                if (escopo != null && !escopo.equals(categoria.getEscopo())) {
                    categoria.setEscopo(escopo);
                    categoriaRepository.save(categoria);
                }
            }
        };
    }
}
