package com.suggesto.backend.controller;

import com.suggesto.backend.service.RecuperacaoSenhaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

// Recuperação de senha por e-mail (ver RecuperacaoSenhaService). Usado pelas
// telas esqueci-senha.html e redefinir-senha.html do site.
@RestController
@RequestMapping("/api/senha")
public class SenhaController {

    public static final String MENSAGEM_PEDIDO =
            "Se o e-mail estiver cadastrado, você receberá um link para redefinir a senha.";

    @Autowired
    private RecuperacaoSenhaService recuperacaoSenhaService;

    // Sempre a mesma resposta, até se der erro no meio: assim ninguém usa esta
    // rota pra descobrir quais e-mails têm conta no Suggesto.
    @PostMapping("/esqueci")
    public ResponseEntity<?> esqueci(@RequestBody Map<String, String> dados) {
        String email = dados.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Digite seu e-mail."
            ));
        }

        try {
            recuperacaoSenhaService.solicitar(email);
        } catch (Exception e) {
            System.err.println("[senha] Falha ao gerar pedido de redefinição: " + e.getClass().getSimpleName());
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", MENSAGEM_PEDIDO
        ));
    }

    @PostMapping("/redefinir")
    public ResponseEntity<?> redefinir(@RequestBody Map<String, String> dados) {
        try {
            recuperacaoSenhaService.redefinir(dados.get("token"), dados.get("senha"));
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Senha alterada com sucesso! Agora é só entrar com a nova senha."
            ));
        } catch (IllegalArgumentException e) {
            // tokenInvalido avisa a tela pra oferecer um link novo em vez de deixar tentar outra senha.
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage(),
                    "tokenInvalido", RecuperacaoSenhaService.TOKEN_INVALIDO.equals(e.getMessage())
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro interno ao redefinir a senha. Tente de novo."
            ));
        }
    }
}
