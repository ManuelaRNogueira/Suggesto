package com.suggesto.backend.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.suggesto.backend.util.UploadStorage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;

@Service
public class CloudinaryService {

    private final Cloudinary cloudinary;

    @Value("${cloudinary.cloud-name:}")
    private String cloudName;

    public CloudinaryService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    // Diz se as credenciais do Cloudinary foram configuradas nas variáveis de ambiente.
    public boolean configurado() {
        return cloudName != null && !cloudName.isBlank();
    }

    // Sobe a foto pro Cloudinary já comprimida (qualidade/formato automáticos,
    // limitada a 1600px) e devolve a URL pública. Sem credenciais configuradas
    // (CLOUDINARY_CLOUD_NAME etc. nas variáveis de ambiente), cai pro disco local
    // pra não travar o desenvolvimento antes de configurar a conta.
    public String upload(MultipartFile arquivo, String pasta, String nomeArquivo) throws IOException {
        if (!configurado()) {
            return salvarLocal(arquivo, nomeArquivo);
        }

        String publicId = nomeArquivo.contains(".")
                ? nomeArquivo.substring(0, nomeArquivo.lastIndexOf('.'))
                : nomeArquivo;

        @SuppressWarnings("unchecked")
        Map<String, Object> resultado = cloudinary.uploader().upload(arquivo.getBytes(), ObjectUtils.asMap(
                "folder", pasta,
                "public_id", publicId,
                "overwrite", true,
                "quality", "auto:good",
                "fetch_format", "auto",
                "width", 1600,
                "height", 1600,
                "crop", "limit"));

        return (String) resultado.get("secure_url");
    }

    // Plano B quando o Cloudinary não está configurado: guarda o arquivo
    // direto no disco do próprio servidor, só pra não travar o desenvolvimento
    // antes de configurar a conta.
    private String salvarLocal(MultipartFile arquivo, String nomeArquivo) throws IOException {
        UploadStorage.garantirDiretorio();
        Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
        Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);
        return nomeArquivo;
    }
}
