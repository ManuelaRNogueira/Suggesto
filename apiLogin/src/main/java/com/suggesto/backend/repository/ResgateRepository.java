package com.suggesto.backend.repository;

import com.suggesto.backend.model.Resgate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ResgateRepository extends JpaRepository<Resgate, Long> {

    long countByUsuario_Id(Long usuarioId);

    List<Resgate> findByUsuario_IdOrderByDataResgateDesc(Long usuarioId);
}
