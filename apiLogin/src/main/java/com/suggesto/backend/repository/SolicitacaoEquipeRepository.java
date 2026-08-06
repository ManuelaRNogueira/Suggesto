package com.suggesto.backend.repository;

import com.suggesto.backend.model.SolicitacaoEquipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SolicitacaoEquipeRepository extends JpaRepository<SolicitacaoEquipe, Long> {

    Optional<SolicitacaoEquipe> findByUsuario_Id(Long usuarioId);

    List<SolicitacaoEquipe> findByEstabelecimento_IdGerenteOrderByDataSolicitacaoAsc(Long idGerente);
}
