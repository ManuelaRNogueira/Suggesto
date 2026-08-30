package com.suggesto.backend.repository;

import com.suggesto.backend.model.SolicitacaoEquipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SolicitacaoEquipeRepository extends JpaRepository<SolicitacaoEquipe, Long> {

    Optional<SolicitacaoEquipe> findByUsuario_IdAndEstabelecimento_IdEstabelecimento(Long usuarioId, Long estabelecimentoId);

    List<SolicitacaoEquipe> findByEstabelecimento_IdGerenteOrderByDataSolicitacaoAsc(Long idGerente);
}
