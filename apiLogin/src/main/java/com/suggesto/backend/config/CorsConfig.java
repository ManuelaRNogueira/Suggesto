package com.suggesto.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
public class CorsConfig {

    // "*" (o default, ver application.properties) libera qualquer origem — igual
    // ao comportamento de sempre. Uma lista separada por vírgula (ex:
    // "http://localhost:5173,https://suggesto-site.onrender.com") restringe às
    // origens listadas, pra quem quiser travar isso via CORS_ALLOWED_ORIGINS.
    @Value("${app.cors.allowed-origins:*}")
    private String origensPermitidas;

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();

        String valor = origensPermitidas == null ? "*" : origensPermitidas.trim();
        if (valor.isEmpty() || valor.equals("*")) {
            config.addAllowedOriginPattern("*");
        } else {
            for (String origem : valor.split(",")) {
                String limpo = origem.trim();
                if (!limpo.isEmpty()) config.addAllowedOriginPattern(limpo);
            }
        }

        config.addAllowedHeader("*");
        config.addAllowedMethod("*");
        config.setAllowCredentials(true);

        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}