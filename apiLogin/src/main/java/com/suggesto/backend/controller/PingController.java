package com.suggesto.backend.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// Endpoint leve para o health check do Render e para o ping externo que impede
// o serviço de hibernar. Não consulta o banco de propósito: é chamado a cada
// poucos minutos e não faz sentido gastar conexão só para responder "estou de pé".
@RestController
@RequestMapping("/api/ping")
@CrossOrigin(origins = "*")
public class PingController {

    @GetMapping
    public Map<String, String> ping() {
        return Map.of("status", "ok");
    }
}
