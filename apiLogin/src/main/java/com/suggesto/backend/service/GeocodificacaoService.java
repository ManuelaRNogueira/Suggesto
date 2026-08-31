package com.suggesto.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

// Converte endereço em coordenadas via Nominatim (OpenStreetMap) — gratuito,
// sem chave, mesmo serviço já usado no app mobile (ver
// suggestomobile/lib/api.dart, buscarCoordenadasEndereco) pro mapa da tela de
// detalhes. Aqui é usado uma vez no cadastro do estabelecimento (ver
// EstabelecimentoController.cadastrar) e no backfill dos que já existiam
// (ver EstabelecimentoController.geocodificarExistentes), nunca a cada
// carregamento de página — não usa java.net.http de forma repetida/em massa.
@Service
public class GeocodificacaoService {

    private static final String USER_AGENT = "SuggestoApp/1.0 (suggesto.app)";

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();

    // Primeiro pergunta o endereço completo (rua + número) pro serviço de
    // mapas. Se ele não souber responder, tenta de novo só com o nome da rua —
    // como perguntar "onde fica a Rua X, 500" e, se ninguém souber, perguntar
    // só "Rua X".
    public double[] geocodificar(String rua, String numero, String cidade, String estado) {
        if (rua == null || rua.isBlank() || cidade == null || cidade.isBlank()) {
            return null;
        }

        if (numero != null && !numero.isBlank()) {
            double[] coords = consultar(String.format("%s, %s, %s, %s", rua, numero, cidade, estado));
            if (coords != null) return coords;
        }

        return consultar(String.format("%s, %s, %s", rua, cidade, estado));
    }

    // Faz a pergunta pro Nominatim de fato: limpa a pontuação do endereço,
    // monta a URL de busca e lê a primeira resposta que ele mandar de volta.
    // Qualquer problema no meio do caminho (sem internet, resposta estranha,
    // endereço que ele não reconhece) é tratado devolvendo null em vez de
    // travar o cadastro do estabelecimento — coordenadas são um "extra", não
    // podem impedir o cadastro de dar certo.
    private double[] consultar(String enderecoTexto) {
        try {
            // Pontuação em nomes como "Princesa D'Oeste" pode impedir o
            // Nominatim de reconhecer um número que existe no mapa.
            String enderecoNormalizado = enderecoTexto
                    .replaceAll("['’`´]", " ")
                    .replaceAll("[,\u2013\u2014-]+", " ")
                    .replaceAll("\\s+", " ")
                    .trim();
            String query = java.net.URLEncoder.encode(enderecoNormalizado, StandardCharsets.UTF_8);
            URI uri = URI.create(
                    "https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=br&q=" + query);

            HttpRequest requisicao = HttpRequest.newBuilder(uri)
                    .header("User-Agent", USER_AGENT)
                    .timeout(Duration.ofSeconds(10))
                    .GET()
                    .build();

            HttpResponse<String> resposta = client.send(requisicao, HttpResponse.BodyHandlers.ofString());
            if (resposta.statusCode() < 200 || resposta.statusCode() >= 300) return null;

            JsonNode lista = mapper.readTree(resposta.body());
            if (!lista.isArray() || lista.isEmpty()) return null;

            JsonNode item = lista.get(0);
            double lat = item.path("lat").asDouble(Double.NaN);
            double lng = item.path("lon").asDouble(Double.NaN);
            if (Double.isNaN(lat) || Double.isNaN(lng)) return null;

            return new double[] { lat, lng };
        } catch (Exception e) {
            return null;
        }
    }
}
