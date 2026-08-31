package com.suggesto.backend.config;



import com.suggesto.backend.util.UploadStorage;

import org.springframework.context.annotation.Configuration;

import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;

import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;



import java.io.IOException;

import java.nio.file.Path;



// Configura como a API entrega os arquivos que foram enviados por upload
// (fotos de perfil, de estabelecimento etc.) — sem isso, o link salvo no
// banco não abriria a imagem de verdade.
@Configuration

public class WebConfig implements WebMvcConfigurer {



    // Garante que a pasta de uploads existe e liga a URL "/uploads/**" na
    // pasta real do disco onde os arquivos ficam salvos.
    @Override

    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        try {

            UploadStorage.garantirDiretorio();

        } catch (IOException e) {

            throw new IllegalStateException("Não foi possível criar a pasta de uploads da API.", e);

        }



        Path uploadDir = UploadStorage.diretorioUploads().toAbsolutePath().normalize();

        String location = uploadDir.toUri().toString();

        if (!location.endsWith("/")) {

            location += "/";

        }



        registry.addResourceHandler("/uploads/**")

                .addResourceLocations(location);

    }

}

