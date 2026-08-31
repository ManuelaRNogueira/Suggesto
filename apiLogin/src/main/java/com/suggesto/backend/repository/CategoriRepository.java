package com.suggesto.backend.repository;


import com.suggesto.backend.model.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

// Repositório extra pra Categoria (mesmo model do CategoriaRepository), mas
// sem métodos próprios — as buscas de verdade (por nome, escopo etc.) são
// feitas pelo CategoriaRepository.
@Repository
public interface CategoriRepository extends JpaRepository<Categoria, Long> {
}
