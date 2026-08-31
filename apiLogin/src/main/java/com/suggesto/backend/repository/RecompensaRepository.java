package com.suggesto.backend.repository;

import com.suggesto.backend.model.Recompensa;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// Repositório das recompensas que cada estabelecimento oferece pra troca por
// pontos (ex: um brinde, um desconto).
public interface RecompensaRepository extends JpaRepository<Recompensa, Long> {

    List<Recompensa> findByEstabelecimento_IdEstabelecimentoOrderByCustoPontosAsc(Long idEstabelecimento);
}
