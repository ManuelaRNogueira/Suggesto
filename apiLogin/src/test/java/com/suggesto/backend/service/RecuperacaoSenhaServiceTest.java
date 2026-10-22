package com.suggesto.backend.service;

import com.suggesto.backend.model.TokenRedefinicaoSenha;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.TokenRedefinicaoSenhaRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

// Roda contra um H2 em memória (o @DataJpaTest troca o MySQL sozinho); só o
// envio de e-mail é falso, pra capturar o link que iria pro usuário.
@DataJpaTest
class RecuperacaoSenhaServiceTest {

    private static final String SITE = "https://site.teste";
    private static final String SENHA_NOVA = "nova#Senha1";

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private TokenRedefinicaoSenhaRepository tokenRepository;

    private EmailService emailService;
    private RecuperacaoSenhaService service;
    private Usuario ana;

    @BeforeEach
    void preparar() {
        emailService = mock(EmailService.class);
        service = new RecuperacaoSenhaService(usuarioRepository, tokenRepository, emailService, SITE + "/");

        Usuario u = new Usuario();
        u.setUsername("ana");
        u.setNome("Ana");
        u.setEmail("ana@x.com");
        u.setSenha(new BCryptPasswordEncoder().encode("antiga#1"));
        u.setTipoUsuario(TipoUsuario.Cliente);
        ana = usuarioRepository.save(u);
    }

    private String pedirEPegarToken(String email) {
        service.solicitar(email);
        ArgumentCaptor<String> link = ArgumentCaptor.forClass(String.class);
        verify(emailService, atLeastOnce()).enviarRedefinicaoSenha(anyString(), any(), link.capture());
        assertThat(link.getValue()).startsWith(SITE + "/redefinir-senha.html?token=");
        return link.getValue().substring(link.getValue().indexOf("token=") + 6);
    }

    private String senhaNoBanco() {
        return usuarioRepository.findById(ana.getId()).orElseThrow().getSenha();
    }

    @Test
    void emailSemDiferenciarMaiusculasGeraTokenEGuardaSoOHash() {
        String token = pedirEPegarToken("  ANA@X.com ");

        assertThat(token).hasSize(43).matches("[A-Za-z0-9_-]+");
        List<TokenRedefinicaoSenha> tokens = tokenRepository.findAll();
        assertThat(tokens).hasSize(1);
        TokenRedefinicaoSenha t = tokens.get(0);
        assertThat(t.getTokenHash()).isEqualTo(RecuperacaoSenhaService.hash(token)).isNotEqualTo(token);
        assertThat(t.isUsado()).isFalse();
        assertThat(t.getExpiraEm()).isEqualTo(t.getCriadoEm().plusMinutes(30));
    }

    @Test
    void emailInexistenteNaoGeraNadaNemEnviaEmail() {
        service.solicitar("ninguem@x.com");

        assertThat(tokenRepository.count()).isZero();
        verifyNoInteractions(emailService);
    }

    @Test
    void segundoPedidoDentroDeDoisMinutosEhIgnorado() {
        pedirEPegarToken("ana@x.com");
        service.solicitar("ana@x.com");

        assertThat(tokenRepository.count()).isEqualTo(1);
        verify(emailService, times(1)).enviarRedefinicaoSenha(anyString(), any(), anyString());
    }

    @Test
    void depoisDeDoisMinutosPodePedirDeNovo() {
        pedirEPegarToken("ana@x.com");
        TokenRedefinicaoSenha t = tokenRepository.findAll().get(0);
        t.setCriadoEm(LocalDateTime.now().minusMinutes(3));
        tokenRepository.save(t);

        service.solicitar("ana@x.com");

        assertThat(tokenRepository.count()).isEqualTo(2);
    }

    @Test
    void redefineSenhaComBcryptEGastaOToken() {
        String token = pedirEPegarToken("ana@x.com");

        service.redefinir(token, SENHA_NOVA);

        assertThat(new BCryptPasswordEncoder().matches(SENHA_NOVA, senhaNoBanco())).isTrue();
        assertThat(tokenRepository.findAll().get(0).isUsado()).isTrue();
        assertThatThrownBy(() -> service.redefinir(token, "outra#Senha2"))
                .hasMessage(RecuperacaoSenhaService.TOKEN_INVALIDO);
    }

    @Test
    void tokenExpiradoOuInexistenteEhRecusado() {
        String token = pedirEPegarToken("ana@x.com");
        TokenRedefinicaoSenha t = tokenRepository.findAll().get(0);
        t.setExpiraEm(LocalDateTime.now().minusSeconds(1));
        tokenRepository.save(t);
        String senhaAntes = senhaNoBanco();

        assertThatThrownBy(() -> service.redefinir(token, SENHA_NOVA))
                .hasMessage(RecuperacaoSenhaService.TOKEN_INVALIDO);
        assertThatThrownBy(() -> service.redefinir("inventado", SENHA_NOVA))
                .hasMessage(RecuperacaoSenhaService.TOKEN_INVALIDO);
        assertThat(senhaNoBanco()).isEqualTo(senhaAntes);
    }

    @Test
    void senhaFracaEhRecusadaSemGastarOToken() {
        String token = pedirEPegarToken("ana@x.com");

        assertThatThrownBy(() -> service.redefinir(token, "1234")).isInstanceOf(IllegalArgumentException.class);

        assertThat(tokenRepository.findAll().get(0).isUsado()).isFalse();
        service.redefinir(token, SENHA_NOVA);
    }

    @Test
    void trocarSenhaInvalidaOsOutrosLinksPendentes() {
        String primeiro = pedirEPegarToken("ana@x.com");
        TokenRedefinicaoSenha t = tokenRepository.findAll().get(0);
        t.setCriadoEm(LocalDateTime.now().minusMinutes(3));
        tokenRepository.save(t);
        String segundo = pedirEPegarToken("ana@x.com");

        service.redefinir(segundo, SENHA_NOVA);

        assertThatThrownBy(() -> service.redefinir(primeiro, "outra#Senha2"))
                .hasMessage(RecuperacaoSenhaService.TOKEN_INVALIDO);
        assertThat(tokenRepository.findAll()).allMatch(TokenRedefinicaoSenha::isUsado);
    }

    @Test
    void contaDoGooglePodeDefinirSenha() {
        ana.setSenha("GOOGLE_SEM_SENHA");
        usuarioRepository.save(ana);
        String token = pedirEPegarToken("ana@x.com");

        service.redefinir(token, SENHA_NOVA);

        assertThat(new BCryptPasswordEncoder().matches(SENHA_NOVA, senhaNoBanco())).isTrue();
    }
}
