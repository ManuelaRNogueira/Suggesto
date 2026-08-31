package com.suggesto.backend.repository;

import com.suggesto.backend.model.Estabelecimento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

// Repositório dos estabelecimentos cadastrados na plataforma (as empresas
// parceiras). É por aqui que o sistema busca, verifica código de acesso e
// checa quais estão ativos.
public interface EstabelecimentoRepository extends JpaRepository<Estabelecimento, Long> {

    // "ativo = 1" porque esse campo é um número (1 = ativo, 0 = inativo), não
    // um true/false — assim só traz os estabelecimentos que estão de fato no ar.
    @Query("SELECT e FROM Estabelecimento e WHERE e.ativo = 1")
    List<Estabelecimento> buscarTodosAtivos();

    // Mesma ideia da busca acima, mas filtrando só os estabelecimentos de um
    // gerente específico.
    @Query("SELECT e FROM Estabelecimento e WHERE e.idGerente = :idGerente AND e.ativo = 1")
    List<Estabelecimento> buscarPorGerenteAtivos(@Param("idGerente") Long idGerente);

    List<Estabelecimento> findByIdGerente(Long idGerente);

    // Usado quando alguém entra com o código de acesso do estabelecimento (ex:
    // pra virar membro da equipe) — só encontra se o estabelecimento estiver ativo.
    @Query("SELECT e FROM Estabelecimento e WHERE e.codigoAcesso = :codigo AND e.ativo = 1")
    Optional<Estabelecimento> findByCodigoAcessoAndAtivo(@Param("codigo") String codigo);

    boolean existsByCodigoAcesso(String codigoAcesso);

    boolean existsByCnpj(String cnpj);

    boolean existsByCnpjAndIdEstabelecimentoNot(String cnpj, long idEstabelecimento);

    boolean existsByIdGerenteAndAtivo(long idGerente, Integer ativo);
}