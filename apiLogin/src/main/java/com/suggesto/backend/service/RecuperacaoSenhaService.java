package com.suggesto.backend.service;

import com.suggesto.backend.model.TokenRedefinicaoSenha;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.TokenRedefinicaoSenhaRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.util.SenhaUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;

// "Esqueci minha senha": gera um link de uso único que chega por e-mail e,
// com ele, deixa a pessoa escolher uma senha nova. Também serve pra conta
// criada pelo Google (senha GOOGLE_SEM_SENHA) passar a ter senha.
@Service
public class RecuperacaoSenhaService {

    public static final Duration VALIDADE = Duration.ofMinutes(30);
    public static final Duration INTERVALO_ENTRE_PEDIDOS = Duration.ofMinutes(2);
    public static final String TOKEN_INVALIDO = "Este link é inválido, expirou ou já foi usado. Peça um novo.";

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UsuarioRepository usuarioRepository;
    private final TokenRedefinicaoSenhaRepository tokenRepository;
    private final EmailService emailService;
    private final String siteUrl;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public RecuperacaoSenhaService(UsuarioRepository usuarioRepository,
                                   TokenRedefinicaoSenhaRepository tokenRepository,
                                   EmailService emailService,
                                   @Value("${app.site-url}") String siteUrl) {
        this.usuarioRepository = usuarioRepository;
        this.tokenRepository = tokenRepository;
        this.emailService = emailService;
        this.siteUrl = siteUrl.endsWith("/") ? siteUrl.substring(0, siteUrl.length() - 1) : siteUrl;
    }

    // Não devolve nada de propósito: quem chama responde a mesma coisa
    // exista a conta ou não, tenha caído no limite ou não.
    @Transactional
    public void solicitar(String email) {
        if (email == null || email.isBlank()) return;

        Optional<Usuario> usuarioOpt = usuarioRepository.findFirstByEmailIgnoreCaseOrderByIdAsc(email.trim().toLowerCase());
        if (usuarioOpt.isEmpty()) return;
        Usuario usuario = usuarioOpt.get();

        LocalDateTime agora = LocalDateTime.now();
        Optional<TokenRedefinicaoSenha> ultimo = tokenRepository.findFirstByUsuarioIdOrderByCriadoEmDesc(usuario.getId());
        if (ultimo.isPresent() && ultimo.get().getCriadoEm().isAfter(agora.minus(INTERVALO_ENTRE_PEDIDOS))) {
            return;
        }

        String token = gerarToken();

        TokenRedefinicaoSenha registro = new TokenRedefinicaoSenha();
        registro.setUsuario(usuario);
        registro.setTokenHash(hash(token));
        registro.setCriadoEm(agora);
        registro.setExpiraEm(agora.plus(VALIDADE));
        registro.setUsado(false);
        tokenRepository.save(registro);

        String link = siteUrl + "/redefinir-senha.html?token=" + token;
        emailService.enviarRedefinicaoSenha(usuario.getEmail(), usuario.getNome(), link);
    }

    // Lança IllegalArgumentException com a mensagem que vai pra tela.
    @Transactional
    public void redefinir(String token, String novaSenha) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException(TOKEN_INVALIDO);
        }

        TokenRedefinicaoSenha registro = tokenRepository.findByTokenHash(hash(token.trim()))
                .orElseThrow(() -> new IllegalArgumentException(TOKEN_INVALIDO));
        if (registro.isUsado() || !registro.getExpiraEm().isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException(TOKEN_INVALIDO);
        }

        // Mesmo tratamento do cadastro e do login, que também fazem trim na senha.
        String senha = novaSenha == null ? null : novaSenha.trim();
        String erro = SenhaUtil.validar(senha);
        if (erro != null) {
            throw new IllegalArgumentException(erro);
        }

        Long idUsuario = registro.getUsuario().getId();
        if (tokenRepository.marcarUsado(registro.getId()) == 0) {
            throw new IllegalArgumentException(TOKEN_INVALIDO);
        }

        // O marcarUsado limpa o contexto do JPA, então o usuário é buscado de novo.
        Usuario usuario = usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> new IllegalArgumentException(TOKEN_INVALIDO));
        usuario.setSenha(passwordEncoder.encode(senha));
        usuarioRepository.save(usuario);

        tokenRepository.invalidarPendentes(idUsuario);
    }

    // 32 bytes aleatórios em base64url (43 caracteres, sem "=") — vai no link sem precisar escapar.
    static String gerarToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hash(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
