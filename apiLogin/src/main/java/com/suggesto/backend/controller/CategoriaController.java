package com.suggesto.backend.controller;

import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.repository.CategoriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categorias")
@CrossOrigin(origins = "*")
public class CategoriaController {

    @Autowired
    private CategoriaRepository categoriaRepository;

    // Devolve sempre todas as categorias — quem decide quais fazem sentido pra
    // cada ramo de estabelecimento agora é o config central do front
    // (js/categoriasPorRamo.js no site, lib/categoriasPorRamo.dart no mobile),
    // não o backend.
    @GetMapping
    public ResponseEntity<List<Categoria>> listar() {
        return ResponseEntity.ok(categoriaRepository.findAll());
    }
}
