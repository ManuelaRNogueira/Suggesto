package com.suggesto.backend.repository;

import com.suggesto.backend.model.Estabelecimento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EstabelecimentoRepository extends JpaRepository<Estabelecimento, Long> {

    @Query("SELECT e FROM Estabelecimento e WHERE e.ativo = 1")
    List<Estabelecimento> buscarTodosAtivos();

    @Query("SELECT e FROM Estabelecimento e WHERE e.idGerente = :idGerente AND e.ativo = 1")
    List<Estabelecimento> buscarPorGerenteAtivos(@Param("idGerente") Long idGerente);

    List<Estabelecimento> findByIdGerente(Long idGerente);

    @Query("SELECT e FROM Estabelecimento e WHERE e.codigoAcesso = :codigo AND e.ativo = 1")
    Optional<Estabelecimento> findByCodigoAcessoAndAtivo(@Param("codigo") String codigo);

    boolean existsByCodigoAcesso(String codigoAcesso);

    boolean existsByCnpj(String cnpj);

    boolean existsByCnpjAndIdEstabelecimentoNot(String cnpj, long idEstabelecimento);

    boolean existsByIdGerenteAndAtivo(long idGerente, Integer ativo);
}