package com.suggesto.backend.repository;

import com.suggesto.backend.model.LocalSalvo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

// Repositório dos locais que o usuário salvou como favoritos — tipo uma
// lista de estabelecimentos marcados pra visitar ou lembrar depois.
public interface LocalSalvoRepository extends JpaRepository<LocalSalvo, Long> {

    long countByUsuarioId(Long usuarioId);

    List<LocalSalvo> findByUsuarioId(Long usuarioId);

    boolean existsByUsuarioIdAndEstabelecimentoId(Long usuarioId, Long estabelecimentoId);

    Optional<LocalSalvo> findByUsuarioIdAndEstabelecimentoId(Long usuarioId, Long estabelecimentoId);
}
