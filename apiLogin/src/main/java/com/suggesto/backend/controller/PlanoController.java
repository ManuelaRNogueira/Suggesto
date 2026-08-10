package com.suggesto.backend.controller;

import com.suggesto.backend.repository.PlanoRepository;
import com.suggesto.backend.service.PlanoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/planos")
@CrossOrigin(origins = "*")
public class PlanoController {

    @Autowired
    private PlanoService planoService;

    @Autowired
    private PlanoRepository planoRepository;

    @GetMapping
    public ResponseEntity<?> listar() {
        return ResponseEntity.ok(planoRepository.findAll());
    }

    // Limites efetivos do administrador logado — o painel usa isso para esconder
    // o que o plano dele não inclui.
    @GetMapping("/meu")
    public ResponseEntity<?> meuPlano(@RequestParam("idUsuario") Long idUsuario) {
        return ResponseEntity.ok(planoService.resumoDoPlano(idUsuario));
    }
}
