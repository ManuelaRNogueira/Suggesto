package com.suggesto.backend.repository;

import com.suggesto.backend.model.MembroEquipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// Repositório dos membros de equipe — quem faz parte do time de cada
// estabelecimento (funcionários/admins vinculados). Usado pra saber quem tem
// acesso a qual estabelecimento.
public interface MembroEquipeRepository extends JpaRepository<MembroEquipe, Long> {

    List<MembroEquipe> findByUsuario_Id(Long usuarioId);

    List<MembroEquipe> findByEstabelecimento_IdEstabelecimentoIn(List<Long> estabelecimentoIds);

    boolean existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(Long usuarioId, Long estabelecimentoId);

    long countByEstabelecimento_IdGerente(Long idGerente);

    void deleteByUsuario_IdAndEstabelecimento_IdEstabelecimento(Long usuarioId, Long estabelecimentoId);
}
