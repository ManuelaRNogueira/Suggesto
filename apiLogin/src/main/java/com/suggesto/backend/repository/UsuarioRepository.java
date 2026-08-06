package com.suggesto.backend.repository;

import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmail(String email);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Usuario u SET u.pontos = u.pontos + :valor WHERE u.id = :id")
    int creditarPontos(@Param("id") Long id, @Param("valor") int valor);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Usuario u SET u.pontos = u.pontos - :custo WHERE u.id = :id AND u.pontos >= :custo")
    int debitarPontos(@Param("id") Long id, @Param("custo") int custo);

        long countByTipoUsuario(TipoUsuario tipoUsuario);
        List<Usuario> findAllByOrderByNomeAsc();

        long countByEstabelecimento_IdGerente(Long idGerente);
        List<Usuario> findByEstabelecimento_IdGerenteOrderByNomeAsc(Long idGerente);
}
