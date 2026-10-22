package com.suggesto.backend.repository;

import com.suggesto.backend.model.TokenRedefinicaoSenha;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface TokenRedefinicaoSenhaRepository extends JpaRepository<TokenRedefinicaoSenha, Long> {

    Optional<TokenRedefinicaoSenha> findByTokenHash(String tokenHash);

    // Último pedido do usuário, pro limite de um pedido a cada 2 minutos.
    Optional<TokenRedefinicaoSenha> findFirstByUsuarioIdOrderByCriadoEmDesc(Long idUsuario);

    // Gasta o token numa única batida (igual ao debitarPontos): se dois
    // pedidos chegarem juntos com o mesmo link, só um recebe 1 aqui.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE TokenRedefinicaoSenha t SET t.usado = true WHERE t.id = :id AND t.usado = false")
    int marcarUsado(@Param("id") Long id);

    // Depois de trocar a senha, os outros links ainda abertos desse usuário deixam de valer.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE TokenRedefinicaoSenha t SET t.usado = true WHERE t.usuario.id = :idUsuario AND t.usado = false")
    int invalidarPendentes(@Param("idUsuario") Long idUsuario);
}
