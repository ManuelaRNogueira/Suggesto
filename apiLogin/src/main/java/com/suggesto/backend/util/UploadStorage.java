package com.suggesto.backend.util;

import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.util.StringUtils;

public class UploadStorage {

    private static final String DIRECTORY_NAME = "uploads";

    public static Path diretorioUploads() {
        return diretorioModulo().resolve(DIRECTORY_NAME);
    }

    // O caminho relativo "uploads" dependia do diretório de trabalho do processo Java,
    // que muda conforme a IDE/terminal usado para rodar — por isso cada máquina acabava
    // enxergando (ou criando) uma pasta de uploads diferente. Ancorar na pasta do módulo
    // (onde fica o target/classes) garante sempre o mesmo local, não importa de onde o app é iniciado.
    private static Path diretorioModulo() {
        try {
            Path codeSource = Paths.get(
                    UploadStorage.class.getProtectionDomain().getCodeSource().getLocation().toURI());
            Path candidato = Files.isRegularFile(codeSource) ? codeSource.getParent() : codeSource;
            if (candidato.endsWith(Paths.get("target", "classes"))) {
                return candidato.getParent().getParent();
            }
            if ("target".equals(String.valueOf(candidato.getFileName()))) {
                return candidato.getParent();
            }
            return candidato;
        } catch (URISyntaxException | NullPointerException e) {
            return Paths.get("").toAbsolutePath();
        }
    }

    public static void garantirDiretorio() throws IOException {
        Path path = diretorioUploads();
        if (!Files.exists(path)) {
            Files.createDirectories(path);
        }
    }

    public static Path resolverArquivo(String nomeArquivo) {
        return diretorioUploads().resolve(nomeArquivo);
    }

    // Trava de segurança: impede que alguém tente salvar um arquivo fora da
    // pasta de uploads usando ".." no nome do arquivo — tipo tentar sair de
    // uma gaveta pra outra sem permissão.
    public static String normalizarNomeArquivo(String nomeArquivo) {
        String limpo = StringUtils.cleanPath(nomeArquivo);
        if (limpo.contains("..")) {
            throw new IllegalArgumentException("Nome de arquivo inválido: " + nomeArquivo);
        }
        return limpo.replaceAll("\\s+", "_");
    }
}