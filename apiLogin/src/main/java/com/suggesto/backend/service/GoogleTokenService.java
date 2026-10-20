package com.suggesto.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Set;

// Valida o ID token do "Entrar com Google" pelo endpoint tokeninfo do próprio
// Google — só HTTP, sem biblioteca nova. A chave secreta do cliente OAuth não
// entra nesse fluxo e não deve ser configurada em lugar nenhum.
@Service
public class GoogleTokenService {

    private static final Set<String> EMISSORES_VALIDOS = Set.of("accounts.google.com", "https://accounts.google.com");

    @Value("${google.client-id:}")
    private String clientId;

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    public record DadosGoogle(String email, String nome, String fotoUrl) {}

    // Devolve os dados do usuário ou lança IllegalArgumentException com a
    // mensagem que vai para a tela.
    public DadosGoogle validar(String idToken) throws Exception {
        if (clientId == null || clientId.isBlank()) {
            throw new IllegalStateException("Login com Google não está configurado no servidor.");
        }
        if (idToken == null || idToken.isBlank()) {
            throw new IllegalArgumentException("Token do Google ausente.");
        }

        URI uri = URI.create("https://oauth2.googleapis.com/tokeninfo?id_token="
                + URLEncoder.encode(idToken, StandardCharsets.UTF_8));
        HttpRequest requisicao = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofSeconds(10))
                .GET()
                .build();

        HttpResponse<String> resposta = client.send(requisicao, HttpResponse.BodyHandlers.ofString());
        if (resposta.statusCode() != 200) {
            throw new IllegalArgumentException("Token do Google inválido ou expirado.");
        }

        JsonNode dados = mapper.readTree(resposta.body());

        if (!clientId.equals(dados.path("aud").asText())) {
            throw new IllegalArgumentException("Token do Google não foi emitido para o Suggesto.");
        }
        if (!EMISSORES_VALIDOS.contains(dados.path("iss").asText())) {
            throw new IllegalArgumentException("Token do Google com emissor inválido.");
        }
        // Sem e-mail verificado, alguém poderia entrar na conta de outra pessoa.
        if (!"true".equals(dados.path("email_verified").asText())) {
            throw new IllegalArgumentException("Seu e-mail do Google ainda não foi verificado.");
        }
        long expiraEm = dados.path("exp").asLong(0);
        if (expiraEm <= System.currentTimeMillis() / 1000) {
            throw new IllegalArgumentException("Token do Google expirado. Tente entrar de novo.");
        }

        String email = dados.path("email").asText("").trim().toLowerCase();
        if (email.isBlank()) {
            throw new IllegalArgumentException("A conta do Google não informou um e-mail.");
        }

        String nome = dados.path("name").asText("").trim();
        String foto = dados.path("picture").asText("").trim();
        return new DadosGoogle(email, nome.isBlank() ? null : nome, foto.isBlank() ? null : foto);
    }
}
