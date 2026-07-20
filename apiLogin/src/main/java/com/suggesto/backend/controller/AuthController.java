package com.suggesto.backend.controller;

import com.suggesto.backend.model.Plano;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.PlanoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api")
public class AuthController {

    @Autowired
    private UsuarioRepository repository;

    @Autowired
    private PlanoRepository planoRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // DDD (11-99) + celular (9 dígitos, iniciando em 9) ou fixo (8 dígitos, iniciando em 2-5)
    private static final Pattern TELEFONE_PATTERN = Pattern.compile("^[1-9][1-9](?:9\\d{8}|[2-5]\\d{7})$");

    private boolean isTelefoneValido(String telefone) {
        String digitos = telefone.replaceAll("\\D", "");
        if (digitos.length() > 11 && digitos.startsWith("55")) {
            digitos = digitos.substring(2);
        }
        return TELEFONE_PATTERN.matcher(digitos).matches();
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginGeral(@RequestBody Map<String, String> dados) {
        return realizarAutenticacao(dados, false);
    }

    @PostMapping("/login/admin")
    public ResponseEntity<?> loginAdmin(@RequestBody Map<String, String> dados) {
        return realizarAutenticacao(dados, true);
    }

    @PostMapping("/cadastro")
    public ResponseEntity<?> cadastrarUsuario(@RequestBody Map<String, Object> dados) {
        try {
            String email = (String) dados.get("email");
            String senha = (String) dados.get("senha");
            String nome = (String) dados.get("nome");
            String tipoStr = (String) dados.get("tipoUsuario");

            if (email == null || senha == null || nome == null || tipoStr == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Nome, e-mail, senha e tipo de usuário são obrigatórios."
                ));
            }

            if (repository.findByEmail(email).isPresent()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Este e-mail já está em uso."
                ));
            }

            TipoUsuario tipoUsuario = TipoUsuario.valueOf(tipoStr);

            Usuario novoUsuario = new Usuario();
            novoUsuario.setNome(nome.trim());
            novoUsuario.setEmail(email.trim());
            novoUsuario.setSenha(passwordEncoder.encode(senha.trim()));
            novoUsuario.setTipoUsuario(tipoUsuario);

            String telefone = (String) dados.get("telefone");
            if (telefone != null && !telefone.isBlank()) {
                if (!isTelefoneValido(telefone)) {
                    return ResponseEntity.badRequest().body(Map.of(
                            "success", false,
                            "message", "Telefone inválido. Informe um número de telefone brasileiro válido, com DDD."
                    ));
                }
                novoUsuario.setTelefone(telefone.trim());
            }
            if (dados.get("cidade") != null) {
                novoUsuario.setCidade(((String) dados.get("cidade")).trim());
            }

            if (tipoUsuario == TipoUsuario.Administrador) {
                if (dados.get("cpf") != null) {
                    novoUsuario.setCpf(((String) dados.get("cpf")).trim());
                }
                if (dados.get("cargo") != null) {
                    novoUsuario.setCargo((String) dados.get("cargo"));
                }

                String nomePlano = (String) dados.get("plano");
                if (nomePlano != null && !nomePlano.isBlank()) {
                    Plano plano = obterOuCriarPlano(nomePlano.trim());
                    novoUsuario.setPlano(plano);
                }
            }

            repository.save(novoUsuario);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Cadastro realizado com sucesso!"
            ));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Tipo de usuário inválido."
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro interno ao cadastrar: " + e.getMessage()
            ));
        }
    }

    private Plano obterOuCriarPlano(String nomePlano) {
        return planoRepository.findByNome(nomePlano).orElseGet(() -> {
            Plano plano = new Plano();
            plano.setNome(nomePlano);

            switch (nomePlano) {
                case "Básico" -> {
                    plano.setDescricao("Para pequenos negócios que estão começando.");
                    plano.setPreco(49.0);
                    plano.setLimiteEstabelecimentos(1);
                }
                case "Pro" -> {
                    plano.setDescricao("Para negócios em crescimento.");
                    plano.setPreco(119.0);
                    plano.setLimiteEstabelecimentos(3);
                }
                case "Empresarial" -> {
                    plano.setDescricao("Para redes com múltiplas unidades.");
                    plano.setPreco(299.0);
                    plano.setLimiteEstabelecimentos(999);
                }
                case "Premium" -> {
                    plano.setDescricao("Plano premium com recursos avançados.");
                    plano.setPreco(199.0);
                    plano.setLimiteEstabelecimentos(5);
                }
                default -> {
                    plano.setDescricao("Plano personalizado.");
                    plano.setPreco(0.0);
                    plano.setLimiteEstabelecimentos(1);
                }
            }

            return planoRepository.save(plano);
        });
    }

    private ResponseEntity<?> realizarAutenticacao(Map<String, String> dados, boolean exigirAdmin) {
        try {
            String email = dados.get("email");
            String senha = dados.get("senha");

            if (email == null || senha == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "E-mail e senha são obrigatórios."
                ));
            }

            Optional<Usuario> usuarioOpt = repository.findByEmail(email);

            if (usuarioOpt.isPresent()) {
                Usuario usuario = usuarioOpt.get();

                if (usuario.getSenha() != null && passwordEncoder.matches(senha.trim(), usuario.getSenha())) {

                    if (usuario.getTipoUsuario() == null) {
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                                "success", false,
                                "message", "Erro: Tipo de usuário não definido no sistema."
                        ));
                    }

                    boolean isAdmin = usuario.getTipoUsuario() == TipoUsuario.Administrador;

                    if (exigirAdmin && !isAdmin) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                                "success", false,
                                "message", "Acesso negado: Apenas administradores."
                        ));
                    }

                    return ResponseEntity.ok(Map.of(
                            "success", true,
                            "message", "Login autorizado",
                            "nome", usuario.getNome() != null ? usuario.getNome() : "Usuário",
                            "idUsuario", usuario.getId(),
                            "tipoUsuario", usuario.getTipoUsuario().name()
                    ));
                }
            }

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "success", false,
                    "message", "E-mail ou senha incorretos."
            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro interno no servidor: " + e.getMessage()
            ));
        }
    }
}
