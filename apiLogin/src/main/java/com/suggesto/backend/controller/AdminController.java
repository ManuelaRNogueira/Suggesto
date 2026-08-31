package com.suggesto.backend.controller;

import com.suggesto.backend.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    @Autowired
    private AdminService adminService;

    // Números do painel administrativo (quantas sugestões chegaram, quantas foram
    // implementadas/recusadas, etc). Quando vem idGerente, é a visão de um gerente
    // específico, só com os estabelecimentos dele; sem idGerente, é a visão geral
    // de quem administra o sistema todo. idEstabelecimento deixa filtrar ainda mais,
    // pra um único estabelecimento.
    @GetMapping("/metricas")
    public ResponseEntity<Map<String, Object>> metricas(
            @RequestParam(value = "idGerente", required = false) Long idGerente,
            @RequestParam(value = "meses", required = false) Integer meses,
            @RequestParam(value = "idEstabelecimento", required = false) Long idEstabelecimento) {
        return ResponseEntity.ok(adminService.obterMetricas(idGerente, meses, idEstabelecimento));
    }

    // Lista as sugestões (avaliações) em si, não só os números — pra tela do
    // painel que mostra cada uma. Mesmo filtro opcional por idGerente de cima.
    @GetMapping("/sugestoes")
    public ResponseEntity<List<Map<String, Object>>> sugestoes(
            @RequestParam(value = "idGerente", required = false) Long idGerente) {
        return ResponseEntity.ok(adminService.listarSugestoes(idGerente));
    }

    // Lista de usuários (clientes) pro painel, no mesmo esquema de filtro por
    // idGerente.
    @GetMapping("/usuarios")
    public ResponseEntity<List<Map<String, Object>>> usuarios(
            @RequestParam(value = "idGerente", required = false) Long idGerente) {
        return ResponseEntity.ok(adminService.listarUsuarios(idGerente));
    }

    // Lista de estabelecimentos pro painel, no mesmo esquema de filtro por
    // idGerente.
    @GetMapping("/estabelecimentos")
    public ResponseEntity<List<Map<String, Object>>> estabelecimentos(
            @RequestParam(value = "idGerente", required = false) Long idGerente) {
        return ResponseEntity.ok(adminService.listarEstabelecimentos(idGerente));
    }
}
