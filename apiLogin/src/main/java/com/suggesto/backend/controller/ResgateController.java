package com.suggesto.backend.controller;

import com.suggesto.backend.service.ResgateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/resgates")
@CrossOrigin(origins = "*")
public class ResgateController {

    @Autowired
    private ResgateService resgateService;

    @GetMapping("/usuario/{idUsuario}")
    public ResponseEntity<?> listarPorUsuario(@PathVariable Long idUsuario) {
        return ResponseEntity.ok(resgateService.listarPorUsuario(idUsuario));
    }

    @PostMapping
    public ResponseEntity<?> resgatar(@RequestBody Map<String, Long> dados) {
        try {
            Long usuarioId = dados.get("usuarioId");
            Long recompensaId = dados.get("recompensaId");

            if (usuarioId == null || recompensaId == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "usuarioId e recompensaId são obrigatórios."
                ));
            }

            return ResponseEntity.ok(resgateService.resgatar(usuarioId, recompensaId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro ao processar resgate: " + e.getMessage()
            ));
        }
    }
}
