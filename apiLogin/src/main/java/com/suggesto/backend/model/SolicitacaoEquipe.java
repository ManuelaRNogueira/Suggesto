package com.suggesto.backend.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "solicitacao_equipe")
@Data
public class SolicitacaoEquipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Unicidade agora é composta (usuario_id, estabelecimento_id) — uma pessoa
    // pode ter pedidos pendentes para estabelecimentos diferentes ao mesmo
    // tempo, só não dois pedidos para o mesmo (ver adicionar_membro_equipe.sql).
    @ManyToOne
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne
    @JoinColumn(name = "estabelecimento_id")
    private Estabelecimento estabelecimento;

    @Column(name = "data_solicitacao")
    private LocalDateTime dataSolicitacao = LocalDateTime.now();
}
