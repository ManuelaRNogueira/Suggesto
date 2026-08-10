package com.suggesto.backend.controller;

import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.util.TextoUtil;
import com.suggesto.backend.util.UploadStorage;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.LocalSalvoRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private static final long MAX_FOTO_BYTES = 5 * 1024 * 1024;
    private static final Set<String> TIPOS_IMAGEM_PERMITIDOS = Set.of(
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/webp"
    );

    @Autowired
    private UsuarioRepository repository;

    @Autowired
    private LocalSalvoRepository localSalvoRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private ResgateRepository resgateRepository;

    @GetMapping("/{id}")
    public ResponseEntity<?> buscarPorId(@PathVariable Long id) {
        try {
            Optional<Usuario> usuarioOpt = repository.findById(id);

            if (usuarioOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "message", "Usuário não encontrado."
                ));
            }

            return ResponseEntity.ok(montarRespostaUsuario(usuarioOpt.get()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", "Erro ao buscar usuário: " + e.getMessage()
            ));
        }
    }

    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> atualizar(
            @PathVariable Long id,
            @RequestParam(value = "nome", required = false) String nome,
            @RequestParam(value = "telefone", required = false) String telefone,
            @RequestParam(value = "cidade", required = false) String cidade,
            @RequestParam(value = "foto", required = false) MultipartFile arquivoFoto) {
        try {
            Optional<Usuario> usuarioOpt = repository.findById(id);

            if (usuarioOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "message", "Usuário não encontrado."
                ));
            }

            Usuario usuario = usuarioOpt.get();

            if (nome != null && !nome.isBlank()) {
                usuario.setNome(nome.trim());
            }
            if (telefone != null) {
                usuario.setTelefone(telefone.isBlank() ? null : telefone.trim());
            }
            if (cidade != null) {
                usuario.setCidade(cidade.isBlank() ? null : TextoUtil.capitalizarNomeProprio(cidade));
            }

            if (arquivoFoto != null && !arquivoFoto.isEmpty()) {
                usuario.setFotoUrl(salvarFotoPerfil(id, arquivoFoto));
            }

            repository.save(usuario);

            return ResponseEntity.ok(montarRespostaUsuario(usuario));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", "Erro ao atualizar usuário: " + e.getMessage()
            ));
        }
    }

    private String salvarFotoPerfil(Long usuarioId, MultipartFile arquivo) throws Exception {
        String contentType = arquivo.getContentType();
        if (contentType == null || !TIPOS_IMAGEM_PERMITIDOS.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException("Formato de imagem não permitido. Use JPEG, PNG, GIF ou WebP.");
        }

        if (arquivo.getSize() > MAX_FOTO_BYTES) {
            throw new IllegalArgumentException("Imagem muito grande. O tamanho máximo é 5 MB.");
        }

        String nomeOriginal = arquivo.getOriginalFilename();
        String nomeSeguro = (nomeOriginal != null && !nomeOriginal.isBlank() ? nomeOriginal : "foto")
                .replaceAll("[^a-zA-Z0-9._-]", "_");

        String nomeArquivo = "usuario_" + usuarioId + "_" + System.currentTimeMillis() + "_" + nomeSeguro;
        Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
        Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);

        return UploadStorage.normalizarNomeArquivo(nomeArquivo);
    }

    private Map<String, Object> montarRespostaUsuario(Usuario usuario) {
        Map<String, Object> resposta = new HashMap<>();
        resposta.put("id", usuario.getId());
        resposta.put("nome", usuario.getNome() != null ? usuario.getNome() : "");
        resposta.put("email", usuario.getEmail() != null ? usuario.getEmail() : "");
        resposta.put("telefone", usuario.getTelefone() != null ? usuario.getTelefone() : "");
        resposta.put("cidade", usuario.getCidade() != null ? usuario.getCidade() : "");
        resposta.put("fotoUrl", formatarFotoUrl(usuario.getFotoUrl()));
        resposta.put("tipoUsuario", usuario.getTipoUsuario() != null ? usuario.getTipoUsuario().name() : "");
        resposta.put("nomePlano", usuario.getPlano() != null ? usuario.getPlano().getNome() : "");
        resposta.put("pontos", usuario.getPontos());
        resposta.put("nivel", usuario.getNivel());
        resposta.put("nivelNome", usuario.getNivelNome());
        resposta.put("totalLocaisSalvos", localSalvoRepository.countByUsuarioId(usuario.getId()));
        resposta.put("totalSugestoes", avaliacaoRepository.countByUsuario_Id(usuario.getId()));
        resposta.put("totalResgates", resgateRepository.countByUsuario_Id(usuario.getId()));
        return resposta;
    }

    private String formatarFotoUrl(String fotoUrl) {
        if (fotoUrl == null || fotoUrl.isBlank()) {
            return "";
        }
        if (fotoUrl.startsWith("http://") || fotoUrl.startsWith("https://") || fotoUrl.startsWith("/uploads/")) {
            return fotoUrl;
        }
        return "/uploads/" + fotoUrl;
    }
}
