package com.suggesto.backend.repository;

import com.suggesto.backend.model.Resgate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// Repositório dos resgates de recompensa feitos pelos clientes (quando
// trocam pontos acumulados por um prêmio).
public interface ResgateRepository extends JpaRepository<Resgate, Long> {

    long countByUsuario_Id(Long usuarioId);

    List<Resgate> findByUsuario_IdOrderByDataResgateDesc(Long usuarioId);

    // Cada cliente só pode resgatar uma recompensa específica uma vez.
    boolean existsByUsuario_IdAndRecompensa_Id(Long usuarioId, Long recompensaId);
}
