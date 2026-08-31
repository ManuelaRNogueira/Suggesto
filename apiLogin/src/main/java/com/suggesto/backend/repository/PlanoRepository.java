package com.suggesto.backend.repository;

import com.suggesto.backend.model.Plano;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// Repositório dos planos de assinatura da plataforma (Básico, Pro,
// Empresarial...) usados pra definir os limites de cada estabelecimento.
public interface PlanoRepository extends JpaRepository<Plano, Long> {

    Optional<Plano> findByNome(String nome);
}
