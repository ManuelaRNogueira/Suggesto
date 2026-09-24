package com.suggesto.backend.repository;

import com.suggesto.backend.model.Visita;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface VisitaRepository extends JpaRepository<Visita, Long> {

    // Visitas ainda dentro da janela, pra reaproveitar em vez de criar outra.
    List<Visita> findByUsuario_IdAndEstabelecimento_IdEstabelecimentoAndDataCheckinAfter(
            Long idUsuario, Long idEstabelecimento, LocalDateTime depoisDe);
}
