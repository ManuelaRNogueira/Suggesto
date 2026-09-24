package com.suggesto.backend.repository;

import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

// Repositório das avaliações/sugestões que os clientes deixam pros
// estabelecimentos — é daqui que vêm os dados pra listar feedbacks, calcular
// notas médias e contar quantas sugestões cada cliente já teve aprovadas.
@Repository
public interface AvaliacaoRepository extends JpaRepository<Avaliacao, Long> {

    @Query("SELECT a FROM Avaliacao a WHERE a.estabelecimento.idEstabelecimento = :id")
    List<Avaliacao> findByEstabelecimentoId(@Param("id") Long id);

    @Query("SELECT a FROM Avaliacao a WHERE a.usuario.id = :usuarioId")
    List<Avaliacao> buscarPorUsuario(@Param("usuarioId") Long usuarioId);

    long countByUsuario_Id(Long usuarioId);

    boolean existsByVisita_Id(Long idVisita);

    // Conta quantas sugestões de um usuário já foram aceitas — como o status é
    // digitado à mão em vários lugares do sistema, aqui a gente ignora
    // maiúscula/minúscula e aceita várias palavras que significam a mesma coisa
    // ("aceita", "aceito", "resolvida"...).
    @Query("SELECT COUNT(a) FROM Avaliacao a WHERE a.usuario.id = :usuarioId "
            + "AND LOWER(TRIM(a.status)) IN ('aceita', 'aceito', 'resolvida', 'resolvido', 'implementado', 'implementada')")
    long contarAprovadasPorUsuario(@Param("usuarioId") Long usuarioId);
    List<Avaliacao> findAllByOrderByDataAvaliacaoDesc();
    List<Avaliacao> findByEstabelecimentoIdEstabelecimentoInOrderByDataAvaliacaoDesc(List<Long> ids);
    long countByEstabelecimentoIdEstabelecimento(long id);

    // Calcula, pra cada estabelecimento, a nota média e quantas avaliações ele
    // recebeu — tudo numa única consulta, em vez de buscar avaliação por
    // avaliação e calcular na mão.
    @Query("SELECT a.estabelecimento.idEstabelecimento, AVG(a.nota), COUNT(a) " +
           "FROM Avaliacao a GROUP BY a.estabelecimento.idEstabelecimento")
    List<Object[]> calcularMediaEContagemPorEstabelecimento();

    // Status das avaliações com visita vinculada de uma lista de usuários, numa
    // única consulta — é o que alimenta a Confiabilidade de vários autores de
    // uma vez (a listagem de sugestões do painel), sem uma consulta por linha.
    @Query("SELECT a.usuario.id, LOWER(TRIM(a.status)) FROM Avaliacao a " +
            "WHERE a.usuario.id IN :idsUsuarios AND a.visita IS NOT NULL")
    List<Object[]> buscarStatusComVisitaPorUsuarios(@Param("idsUsuarios") List<Long> idsUsuarios);

    // Dados brutos de todas as avaliações de um estabelecimento, pra calcular a
    // Transparência (taxa de resposta, taxa de recusa, agilidade) na hora.
    @Query("SELECT a.status, a.dataAvaliacao, a.dataResposta, a.dataDecisao, a.resposta " +
            "FROM Avaliacao a WHERE a.estabelecimento.idEstabelecimento = :idEstabelecimento")
    List<Object[]> buscarDadosReputacaoEstabelecimento(@Param("idEstabelecimento") Long idEstabelecimento);
}