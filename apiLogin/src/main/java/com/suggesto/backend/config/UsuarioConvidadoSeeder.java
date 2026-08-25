package com.suggesto.backend.config;

import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.UUID;

// Usuário fixo usado para sugestões enviadas sem login (ex: QR code na feira,
// onde não queremos obrigar cadastro). A senha é um valor aleatório descartado
// na hora, então essa conta não é utilizável para login — só serve como dono
// das avaliações anônimas. Roda em todo boot e é idempotente.
@Configuration
public class UsuarioConvidadoSeeder {

    public static final String USERNAME_CONVIDADO = "convidado_suggesto";

    @Bean
    public ApplicationRunner criarUsuarioConvidado(UsuarioRepository usuarioRepository) {
        return args -> {
            if (usuarioRepository.findByUsername(USERNAME_CONVIDADO).isPresent()) {
                return;
            }

            Usuario convidado = new Usuario();
            convidado.setNome("Convidado");
            convidado.setUsername(USERNAME_CONVIDADO);
            convidado.setEmail("convidado@suggesto.app");
            convidado.setSenha(new BCryptPasswordEncoder().encode(UUID.randomUUID().toString()));
            convidado.setTipoUsuario(TipoUsuario.Cliente);
            usuarioRepository.save(convidado);
        };
    }
}
