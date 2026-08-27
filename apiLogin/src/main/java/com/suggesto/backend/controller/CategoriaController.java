package com.suggesto.backend.controller;

import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.repository.CategoriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/categorias")
@CrossOrigin(origins = "*")
public class CategoriaController {

    @Autowired
    private CategoriaRepository categoriaRepository;

    // Tipos de estabelecimento que servem comida/bebida — só eles mostram a
    // categoria de sugestão "Cardápio" (escopo COMIDA).
    private static final Set<String> TIPOS_COMIDA = Set.of(
            "Restaurante", "Bar", "Lanchonete", "Pizzaria", "Cafeteria", "Padaria",
            "Sorveteria", "Hamburgueria", "Doceria / Confeitaria", "Açaiteria", "Food Truck"
    );

    // Tipos de estabelecimento sem espaço físico visitado pelo cliente — não
    // mostram categorias de escopo FISICO (Estrutura, Ambiente, Higiene).
    private static final Set<String> TIPOS_NAO_FISICOS = Set.of(
            "Escritório / Empresa (Tecnologia e Serviços)"
    );

    // Sem "tipoEstabelecimento", devolve todas (uso administrativo). Com o
    // parâmetro, filtra pelo escopo de cada categoria conforme o tipo do
    // estabelecimento que está recebendo a sugestão.
    @GetMapping
    public ResponseEntity<List<Categoria>> listar(
            @RequestParam(value = "tipoEstabelecimento", required = false) String tipoEstabelecimento) {
        List<Categoria> todas = categoriaRepository.findAll();

        if (tipoEstabelecimento == null || tipoEstabelecimento.isBlank()) {
            return ResponseEntity.ok(todas);
        }

        boolean fisico = !TIPOS_NAO_FISICOS.contains(tipoEstabelecimento);
        boolean comida = TIPOS_COMIDA.contains(tipoEstabelecimento);

        List<Categoria> filtradas = todas.stream()
                .filter(c -> "TODOS".equals(c.getEscopo())
                        || ("FISICO".equals(c.getEscopo()) && fisico)
                        || ("COMIDA".equals(c.getEscopo()) && comida))
                .toList();

        return ResponseEntity.ok(filtradas);
    }
}
