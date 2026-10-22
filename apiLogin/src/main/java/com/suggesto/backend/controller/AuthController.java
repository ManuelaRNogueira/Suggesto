package com.suggesto.backend.controller;

import com.suggesto.backend.model.Plano;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.PlanoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.service.GoogleTokenService;
import com.suggesto.backend.util.DocumentoValidator;
import com.suggesto.backend.util.SenhaUtil;
import com.suggesto.backend.util.TextoUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
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

    @Autowired
    private GoogleTokenService googleTokenService;

    // A senha passa por um "moedor" de mão única (BCrypt): dá pra transformar
    // a senha original nesse resultado embaralhado, mas é impossível fazer o
    // caminho contrário. Por isso, pra logar, a gente não "descriptografa"
    // nada — passa a senha digitada pelo mesmo moedor de novo e compara os
    // dois resultados.
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // Esse padrão confere se o telefone digitado tem o formato de um número
    // brasileiro de verdade: DDD válido + celular (9 dígitos) ou fixo (8).
    private static final Pattern TELEFONE_PATTERN = Pattern.compile("^[1-9][1-9](?:9\\d{8}|[2-5]\\d{7})$");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[\\w.%+-]+@[\\w.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[a-zA-Z0-9._]{3,30}$");

    // Tira tudo que não é dígito e, se sobrar um número com DDI do Brasil (55)
    // na frente, tira o DDI também — assim "+55 11 91234-5678" e "11912345678"
    // caem no mesmo formato antes de checar contra o padrão.
    private boolean isTelefoneValido(String telefone) {
        String digitos = telefone.replaceAll("\\D", "");
        if (digitos.length() > 11 && digitos.startsWith("55")) {
            digitos = digitos.substring(2);
        }
        return TELEFONE_PATTERN.matcher(digitos).matches();
    }

    // Login usado pelo app do cliente comum — aceita qualquer tipo de usuário.
    @PostMapping("/login")
    public ResponseEntity<?> loginGeral(@RequestBody Map<String, String> dados) {
        return realizarAutenticacao(dados, false);
    }

    // Login do painel administrativo — mesma verificação de e-mail/senha, mas
    // aqui barra quem não é Administrador (ver realizarAutenticacao).
    @PostMapping("/login/admin")
    public ResponseEntity<?> loginAdmin(@RequestBody Map<String, String> dados) {
        return realizarAutenticacao(dados, true);
    }

    // Cadastro de conta nova (cliente ou administrador de estabelecimento).
    // É uma cascata de validações que vai checando um campo de cada vez e
    // devolvendo 400 assim que algo não bate — e-mail com formato válido e
    // ainda não usado, username no padrão certo e livre, telefone (se
    // informado) num formato brasileiro válido e não repetido. Se for
    // cadastro de Administrador, ainda valida CPF e associa (ou cria) o plano
    // escolhido.
    @PostMapping("/cadastro")
    public ResponseEntity<?> cadastrarUsuario(@RequestBody Map<String, Object> dados) {
        try {
            String email = (String) dados.get("email");
            String senha = (String) dados.get("senha");
            String nome = (String) dados.get("nome");
            String tipoStr = (String) dados.get("tipoUsuario");

            if (email == null || senha == null || nome == null || tipoStr == null || senha.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Nome, e-mail, senha e tipo de usuário são obrigatórios."
                ));
            }

            email = normalizarEmail(email);

            if (!EMAIL_PATTERN.matcher(email).matches()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Digite um e-mail válido."
                ));
            }

            if (repository.findFirstByEmailIgnoreCaseOrderByIdAsc(email).isPresent()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Este e-mail já está em uso."
                ));
            }

            String erroSenha = SenhaUtil.validar(senha.trim());
            if (erroSenha != null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", erroSenha
                ));
            }

            Object usernameObj = dados.get("username");
            String username = usernameObj != null ? usernameObj.toString().trim() : "";
            if (username.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Nome de usuário é obrigatório."
                ));
            }
            if (!USERNAME_PATTERN.matcher(username).matches()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Nome de usuário deve ter de 3 a 30 caracteres e usar apenas letras, números, pontos ou underscores."
                ));
            }
            if (repository.existsByUsername(username)) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Este nome de usuário já está em uso."
                ));
            }

            TipoUsuario tipoUsuario = TipoUsuario.valueOf(tipoStr);

            Usuario novoUsuario = new Usuario();
            novoUsuario.setNome(nome.trim());
            novoUsuario.setUsername(username);
            novoUsuario.setEmail(email);
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
                String telefoneNormalizado = telefone.trim();
                if (repository.existsByTelefone(telefoneNormalizado)) {
                    return ResponseEntity.badRequest().body(Map.of(
                            "success", false,
                            "message", "Este telefone já está cadastrado."
                    ));
                }
                novoUsuario.setTelefone(telefoneNormalizado);
            }
            if (dados.get("cidade") != null) {
                novoUsuario.setCidade(TextoUtil.normalizarCidade((String) dados.get("cidade")));
            }
            if (dados.get("cep") != null) {
                novoUsuario.setCep(((String) dados.get("cep")).trim());
            }
            if (dados.get("estado") != null) {
                novoUsuario.setEstado(((String) dados.get("estado")).trim().toUpperCase());
            }

            if (tipoUsuario == TipoUsuario.Administrador) {
                if (dados.get("cpf") != null) {
                    String cpf = ((String) dados.get("cpf")).trim();
                    if (!cpf.isBlank()) {
                        if (!DocumentoValidator.isCpfValido(cpf)) {
                            return ResponseEntity.badRequest().body(Map.of(
                                    "success", false,
                                    "message", "CPF inválido."
                            ));
                        }
                        if (repository.existsByCpf(cpf)) {
                            return ResponseEntity.badRequest().body(Map.of(
                                    "success", false,
                                    "message", "Este CPF já está cadastrado."
                            ));
                        }
                        novoUsuario.setCpf(cpf);
                    }
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

            Usuario salvo = repository.save(novoUsuario);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Cadastro realizado com sucesso!",
                    "idUsuario", salvo.getId()
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

    // Os três planos oficiais (Básico/Pro/Empresarial) são criados e mantidos pelo
    // PlanoSeeder, que é a fonte da verdade dos limites descritos em planos.html.
    // Aqui só cai um nome fora dessa lista.
    private Plano obterOuCriarPlano(String nomePlano) {
        return planoRepository.findByNome(nomePlano).orElseGet(() -> {
            Plano plano = new Plano();
            plano.setNome(nomePlano);
            plano.setDescricao("Plano personalizado.");
            plano.setPreco(0.0);
            plano.setLimiteEstabelecimentos(1);
            return planoRepository.save(plano);
        });
    }

    // Contas criadas pelo Google não têm senha: guardam este valor, que não é um
    // hash BCrypt, então passwordEncoder.matches nunca aceita nada contra ele.
    private static final String SENHA_CONTA_GOOGLE = "GOOGLE_SEM_SENHA";

    private static String normalizarEmail(String email) {
        return email.trim().toLowerCase();
    }

    // "Entrar com Google": o front manda o ID token, o GoogleTokenService confere
    // com o Google (aud, iss, e-mail verificado, validade). Cliente existente
    // entra; e-mail novo vira cliente; administrador é recusado (entra com senha).
    @PostMapping("/login/google")
    public ResponseEntity<?> loginGoogle(@RequestBody Map<String, String> dados) {
        try {
            GoogleTokenService.DadosGoogle google = googleTokenService.validar(dados.get("credential"));

            Optional<Usuario> usuarioOpt = repository.findFirstByEmailIgnoreCaseOrderByIdAsc(google.email());
            Usuario usuario;

            if (usuarioOpt.isPresent()) {
                usuario = usuarioOpt.get();
                if (usuario.getTipoUsuario() == TipoUsuario.Administrador) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                            "success", false,
                            "message", "Administradores entram com e-mail e senha."
                    ));
                }
                if (usuario.getTipoUsuario() == null) {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                            "success", false,
                            "message", "Erro: Tipo de usuário não definido no sistema."
                    ));
                }
            } else {
                usuario = new Usuario();
                usuario.setNome(google.nome() != null ? google.nome() : google.email().substring(0, google.email().indexOf('@')));
                usuario.setUsername(gerarUsernameUnico(google.email()));
                usuario.setEmail(google.email());
                usuario.setSenha(SENHA_CONTA_GOOGLE);
                usuario.setTipoUsuario(TipoUsuario.Cliente);
                usuario.setFotoUrl(google.fotoUrl());
                usuario = repository.save(usuario);
            }

            // Mesma resposta do login normal, mais o e-mail (o front não tem um
            // campo digitado para guardar) e o aviso de perfil incompleto.
            Map<String, Object> resposta = new HashMap<>(montarRespostaLogin(usuario));
            resposta.put("email", usuario.getEmail());
            resposta.put("perfilIncompleto", isBlank(usuario.getCidade()) || isBlank(usuario.getCep()));
            return ResponseEntity.ok(resposta);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro interno no login com Google: " + e.getMessage()
            ));
        }
    }

    private static boolean isBlank(String texto) {
        return texto == null || texto.isBlank();
    }

    // maria.silva@gmail.com -> maria.silva, maria.silva2, maria.silva3...
    // Mesmo padrão do cadastro (USERNAME_PATTERN); o cliente pode trocar no perfil.
    private String gerarUsernameUnico(String email) {
        String base = email.substring(0, email.indexOf('@')).replaceAll("[^a-z0-9._]", "");
        if (base.length() < 3) {
            base = base + "usuario";
        }
        if (base.length() > 25) {
            base = base.substring(0, 25);
        }

        String candidato = base;
        int sufixo = 2;
        while (repository.existsByUsername(candidato)) {
            candidato = base + sufixo++;
        }
        return candidato;
    }

    // Resposta de login compartilhada pelo e-mail/senha e pelo Google.
    private Map<String, Object> montarRespostaLogin(Usuario usuario) {
        return Map.of(
                "success", true,
                "message", "Login autorizado",
                "nome", usuario.getNome() != null ? usuario.getNome() : "Usuário",
                "idUsuario", usuario.getId(),
                "tipoUsuario", usuario.getTipoUsuario().name()
        );
    }

    // Lógica de fato do login, compartilhada pelas duas rotas acima. Busca o
    // usuário pelo e-mail, confere a senha com o BCrypt (ver comentário do
    // passwordEncoder) e, se exigirAdmin for true (rota /login/admin), ainda
    // bloqueia quem não é do tipo Administrador com 403. Por segurança, e-mail
    // não encontrado e senha errada caem na mesma mensagem genérica — não dá
    // pra alguém de fora descobrir se um e-mail existe ou não no sistema.
    private ResponseEntity<?> realizarAutenticacao(Map<String, String> dados, boolean exigirAdmin) {
        try {
            String email = dados.get("email");
            String senha = dados.get("senha");

            // Senha vazia nunca é aceita, nem para contas criadas pelo Google.
            if (email == null || senha == null || email.isBlank() || senha.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "E-mail e senha são obrigatórios."
                ));
            }

            Optional<Usuario> usuarioOpt = repository.findFirstByEmailIgnoreCaseOrderByIdAsc(normalizarEmail(email));

            if (usuarioOpt.isPresent()) {
                Usuario usuario = usuarioOpt.get();

                if (usuario.getSenha() != null && !SENHA_CONTA_GOOGLE.equals(usuario.getSenha())
                        && passwordEncoder.matches(senha.trim(), usuario.getSenha())) {

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

                    return ResponseEntity.ok(montarRespostaLogin(usuario));
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
