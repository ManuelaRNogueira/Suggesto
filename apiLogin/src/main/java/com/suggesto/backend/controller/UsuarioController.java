package com.suggesto.backend.controller;

import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.util.TextoUtil;
import com.suggesto.backend.util.UploadStorage;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.LocalSalvoRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.service.CloudinaryService;
import com.suggesto.backend.service.ConquistaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

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

    @Autowired
    private ConquistaService conquistaService;

    @Autowired
    private CloudinaryService cloudinaryService;

    // Cria um usuário convidado novo (Convidado 1, Convidado 2...) pra quem chega
    // sem login via QR code, um por dispositivo/navegador — assim dá pra navegar
    // pelo app "logado" sem precisar se cadastrar, e sem misturar o histórico de
    // pessoas diferentes num único convidado compartilhado. A senha é aleatória e
    // descartada na hora, então essa conta nunca é utilizável pra login.
    @PostMapping("/convidado")
    public ResponseEntity<?> criarConvidado() {
        try {
            Usuario convidado = new Usuario();
            convidado.setTipoUsuario(TipoUsuario.Cliente);
            convidado.setSenha(new BCryptPasswordEncoder().encode(UUID.randomUUID().toString()));
            convidado = repository.save(convidado);

            convidado.setNome("Convidado " + convidado.getId());
            convidado.setUsername("convidado_" + convidado.getId());
            convidado.setEmail("convidado" + convidado.getId() + "@suggesto.app");
            convidado = repository.save(convidado);

            return ResponseEntity.ok(Map.of(
                    "idUsuario", convidado.getId(),
                    "nome", convidado.getNome()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro ao criar convidado: " + e.getMessage()
            ));
        }
    }

    // Dados do perfil do usuário (nome, foto, pontos, nível, plano...) pra tela
    // de perfil. A montagem da resposta fica no montarRespostaUsuario logo
    // abaixo, que já cuida de campos nulos e busca os totais (locais salvos,
    // sugestões, resgates) de outras tabelas.
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

    // Lista as conquistas (tipo medalhas/badges) que o usuário já desbloqueou,
    // pra tela de perfil/gamificação.
    @GetMapping("/{id}/conquistas")
    public ResponseEntity<?> listarConquistas(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(conquistaService.listarPorUsuario(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    // Edição de perfil. É multipart (não JSON comum) porque pode vir uma foto
    // nova junto. Cada campo só é alterado se vier preenchido na requisição —
    // não manda telefone/cidade e o valor antigo continua intacto; manda vazio
    // de propósito e o campo é limpo. A validação de tipo/tamanho da foto fica
    // em salvarFotoPerfil, logo abaixo.
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
                usuario.setCidade(cidade.isBlank() ? null : TextoUtil.normalizarCidade(cidade));
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

    // Confere se o arquivo é mesmo uma imagem de um formato aceito e se não
    // passa de 5 MB antes de mandar pro Cloudinary — barato de checar aqui,
    // evita gastar upload com um arquivo que ia ser rejeitado de qualquer jeito.
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
        return cloudinaryService.upload(arquivo, "usuarios", nomeArquivo);
    }

    private Map<String, Object> montarRespostaUsuario(Usuario usuario) {
        Map<String, Object> resposta = new HashMap<>();
        resposta.put("id", usuario.getId());
        resposta.put("nome", usuario.getNome() != null ? usuario.getNome() : "");
        resposta.put("email", usuario.getEmail() != null ? usuario.getEmail() : "");
        resposta.put("telefone", usuario.getTelefone() != null ? usuario.getTelefone() : "");
        resposta.put("cidade", usuario.getCidade() != null ? usuario.getCidade() : "");
        resposta.put("cep", usuario.getCep() != null ? usuario.getCep() : "");
        resposta.put("estado", usuario.getEstado() != null ? usuario.getEstado() : "");
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
