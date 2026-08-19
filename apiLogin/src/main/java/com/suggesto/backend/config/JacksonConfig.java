package com.suggesto.backend.config;

import com.fasterxml.jackson.datatype.jsr310.ser.LocalDateTimeSerializer;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

// Todo campo LocalDateTime do backend (Avaliacao.dataAvaliacao/dataResposta,
// SolicitacaoEquipe.dataSolicitacao, LocalSalvo.dataSalvo, Resgate.dataResgate)
// é preenchido com LocalDateTime.now() — e a JVM roda em UTC (o Dockerfile não
// configura TZ, a imagem eclipse-temurin usa UTC por padrão). Ou seja, o valor
// já É um instante UTC, mas o Jackson serializava sem marcar isso
// ("2026-08-18T14:22:35"), e cada front (mobile/web/desktop) lia como se já
// fosse hora local — mostrando o horário errado (deslocado pelo fuso do
// servidor). Aqui só deixamos explícito no JSON que é UTC (sufixo "Z"), sem
// mudar o tipo do campo nem o schema do banco.
@Configuration
public class JacksonConfig implements Jackson2ObjectMapperBuilderCustomizer {

    private static final DateTimeFormatter FORMATO_UTC =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'");

    @Override
    public void customize(Jackson2ObjectMapperBuilder builder) {
        builder.serializerByType(LocalDateTime.class, new LocalDateTimeSerializer(FORMATO_UTC));
    }
}
