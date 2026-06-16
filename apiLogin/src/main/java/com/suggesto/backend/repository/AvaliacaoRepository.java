package com.suggesto.backend.repository;

import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AvaliacaoRepository extends JpaRepository<Avaliacao, Long> {

    @Query("SELECT a FROM Avaliacao a WHERE a.estabelecimento.idEstabelecimento = :id")
    List<Avaliacao> findByEstabelecimentoId(@Param("id") Long id);

    @Query("SELECT a FROM Avaliacao a WHERE a.usuario.id = :usuarioId")
    List<Avaliacao> buscarPorUsuario(@Param("usuarioId") Long usuarioId);

    long countByUsuario_Id(Long usuarioId);
    List<Avaliacao> findAllByOrderByDataAvaliacaoDesc();
    List<Avaliacao> findByEstabelecimentoIdEstabelecimentoInOrderByDataAvaliacaoDesc(List<Long> ids);
    long countByEstabelecimentoIdEstabelecimento(long id);
}