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

    @GetMapping("/metricas")
    public ResponseEntity<Map<String, Object>> metricas(
            @RequestParam(value = "idGerente", required = false) Long idGerente,
            @RequestParam(value = "meses", required = false) Integer meses) {
        return ResponseEntity.ok(adminService.obterMetricas(idGerente, meses));
    }

    @GetMapping("/sugestoes")
    public ResponseEntity<List<Map<String, Object>>> sugestoes(
            @RequestParam(value = "idGerente", required = false) Long idGerente) {
        return ResponseEntity.ok(adminService.listarSugestoes(idGerente));
    }

    @GetMapping("/usuarios")
    public ResponseEntity<List<Map<String, Object>>> usuarios() {
        return ResponseEntity.ok(adminService.listarUsuarios());
    }

    @GetMapping("/estabelecimentos")
    public ResponseEntity<List<Map<String, Object>>> estabelecimentos(
            @RequestParam(value = "idGerente", required = false) Long idGerente) {
        return ResponseEntity.ok(adminService.listarEstabelecimentos(idGerente));
    }
}
