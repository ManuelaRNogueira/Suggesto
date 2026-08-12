package com.suggesto.backend.controller;

import com.suggesto.backend.repository.PlanoRepository;
import com.suggesto.backend.service.PlanoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

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

    // Troca o plano do administrador principal. Erros de limite/permissão viram
    // o texto puro da mensagem, no mesmo padrão do POST /api/estabelecimentos.
    @PutMapping("/meu")
    public ResponseEntity<?> trocarPlano(@RequestBody Map<String, Object> dados) {
        try {
            Long idUsuario = Long.valueOf(String.valueOf(dados.get("idUsuario")));
            String nomePlano = (String) dados.get("plano");
            planoService.trocarPlano(idUsuario, nomePlano);
            return ResponseEntity.ok(planoService.resumoDoPlano(idUsuario));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(403).body(e.getMessage());
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
