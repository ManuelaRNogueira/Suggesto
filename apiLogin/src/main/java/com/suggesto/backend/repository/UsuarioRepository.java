package com.suggesto.backend.repository;

import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

// Aqui é onde a gente busca, salva e atualiza os usuários no banco de dados —
// login, cadastro, pontos de fidelidade, tudo que envolve a tabela de
// usuários passa por aqui.
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmail(String email);

    Optional<Usuario> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByCpf(String cpf);

    boolean existsByTelefone(String telefone);

    // Soma pontos na conta do usuário direto no banco (ex: um bônus ou um
    // ajuste), sem precisar carregar o usuário inteiro pra depois salvar de novo.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Usuario u SET u.pontos = u.pontos + :valor WHERE u.id = :id")
    int creditarPontos(@Param("id") Long id, @Param("valor") int valor);

    // Isso funciona como um caixa de banco: só deixa sacar (descontar pontos)
    // se o saldo for suficiente, e checa o saldo e desconta numa única batida —
    // assim, mesmo que duas pessoas tentem resgatar ao mesmo tempo, ninguém
    // fica no negativo.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Usuario u SET u.pontos = u.pontos - :custo WHERE u.id = :id AND u.pontos >= :custo")
    int debitarPontos(@Param("id") Long id, @Param("custo") int custo);

        long countByTipoUsuario(TipoUsuario tipoUsuario);
        List<Usuario> findAllByOrderByNomeAsc();
}
