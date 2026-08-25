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

    // Retorna {lat, lng} ou null se não conseguir localizar o endereço.
    // Tenta rua+número primeiro; se não achar, tenta só a rua (o bairro não
    // entra na busca — nome cadastrado no banco nem sempre bate com o do OSM
    // pra aquele trecho, e isso fazia a busca falhar mesmo com rua/cidade certos).
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

    private double[] consultar(String enderecoTexto) {
        try {
            String query = java.net.URLEncoder.encode(enderecoTexto, StandardCharsets.UTF_8);
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
