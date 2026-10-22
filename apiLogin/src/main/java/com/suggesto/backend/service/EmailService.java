package com.suggesto.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;

// Manda e-mail pela API HTTP do Brevo — só HTTP, sem biblioteca nova. Não dá
// pra usar SMTP porque o Render gratuito bloqueia as portas de e-mail.
// A chave vem de BREVO_API_KEY e nunca aparece em log: nem ela, nem o link.
@Service
public class EmailService {

    private static final String URL_BREVO = "https://api.brevo.com/v3/smtp/email";

    @Value("${brevo.api-key:}")
    private String apiKey;

    @Value("${brevo.remetente-nome:Suggesto}")
    private String remetenteNome;

    @Value("${brevo.remetente-email:projetosuggesto@gmail.com}")
    private String remetenteEmail;

    // Ligado só no profile "local" (application-local.properties): sem chave
    // do Brevo, escreve o link no console pra dar pra testar sem mandar e-mail.
    @Value("${app.email.logar-link-sem-chave:false}")
    private boolean logarLinkSemChave;

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    // Não espera o Brevo responder: assim o "esqueci minha senha" demora o
    // mesmo tanto exista a conta ou não, e o tempo de resposta não entrega
    // quais e-mails estão cadastrados.
    public void enviarRedefinicaoSenha(String para, String nome, String link) {
        if (apiKey == null || apiKey.isBlank()) {
            if (logarLinkSemChave) {
                System.out.println("[email] BREVO_API_KEY ausente, e-mail não enviado. Link de redefinição para "
                        + para + ": " + link);
            } else {
                System.err.println("[email] BREVO_API_KEY não configurada: e-mail de redefinição de senha não enviado.");
            }
            return;
        }

        String nomeSeguro = HtmlUtils.htmlEscape(nome != null && !nome.isBlank() ? nome : "tudo bem");
        String html = "<p>Olá, " + nomeSeguro + "!</p>"
                + "<p>Recebemos um pedido para redefinir a senha da sua conta no Suggesto.</p>"
                + "<p><a href=\"" + link + "\">Clique aqui para criar uma nova senha</a></p>"
                + "<p>O link vale por 30 minutos e só pode ser usado uma vez.</p>"
                + "<p>Se não foi você que pediu, ignore este e-mail: sua senha continua a mesma.</p>";
        String texto = "Recebemos um pedido para redefinir a senha da sua conta no Suggesto.\n\n"
                + "Abra este link para criar uma nova senha (vale por 30 minutos, uma vez só):\n" + link + "\n\n"
                + "Se não foi você que pediu, ignore este e-mail: sua senha continua a mesma.";

        CompletableFuture.runAsync(() -> enviar(para, "Redefinição de senha - Suggesto", html, texto));
    }

    private void enviar(String para, String assunto, String html, String texto) {
        try {
            ObjectNode corpo = mapper.createObjectNode();
            corpo.putObject("sender").put("name", remetenteNome).put("email", remetenteEmail);
            corpo.putArray("to").addObject().put("email", para);
            corpo.put("subject", assunto);
            corpo.put("htmlContent", html);
            corpo.put("textContent", texto);

            HttpRequest requisicao = HttpRequest.newBuilder(URI.create(URL_BREVO))
                    .timeout(Duration.ofSeconds(15))
                    .header("api-key", apiKey)
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(corpo)))
                    .build();

            HttpResponse<String> resposta = client.send(requisicao, HttpResponse.BodyHandlers.ofString());
            if (resposta.statusCode() < 200 || resposta.statusCode() >= 300) {
                // Só o status e o código de erro do Brevo: o corpo enviado tem o link.
                String codigo = "";
                try {
                    JsonNode erro = mapper.readTree(resposta.body());
                    codigo = erro.path("code").asText("") + " " + erro.path("message").asText("");
                } catch (Exception ignorado) {
                }
                System.err.println("[email] Brevo recusou o e-mail (status " + resposta.statusCode() + ") " + codigo.trim());
                return;
            }
            // O messageId permite achar o envio nos logs do Brevo (Transacional > Logs).
            String messageId = "";
            try {
                messageId = mapper.readTree(resposta.body()).path("messageId").asText("");
            } catch (Exception ignorado) {
            }
            System.out.println("[email] Brevo aceitou o e-mail (status " + resposta.statusCode() + ") messageId " + messageId);
        } catch (Throwable e) {
            // Throwable: dentro do runAsync, um erro não capturado sumiria sem deixar rastro.
            System.err.println("[email] Falha ao chamar o Brevo: " + e.getClass().getSimpleName());
        }
    }
}
