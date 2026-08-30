package com.suggesto.backend.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

// Vínculo entre uma pessoa e um estabelecimento cuja equipe ela integra. Uma
// pessoa pode ter várias linhas aqui (funcionária de vários lugares, ou dona
// de um e funcionária de outro ao mesmo tempo) — ver adicionar_membro_equipe.sql.
// Todo dono também ganha uma linha para o próprio estabelecimento, então "quem
// trabalha aqui" é sempre uma única consulta por estabelecimento, sem caso
// especial para o dono.
@Entity
@Table(
        name = "membro_equipe",
        uniqueConstraints = @UniqueConstraint(columnNames = {"usuario_id", "estabelecimento_id"})
)
@Data
public class MembroEquipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne
    @JoinColumn(name = "estabelecimento_id")
    private Estabelecimento estabelecimento;

    @Column(name = "data_entrada")
    private LocalDateTime dataEntrada = LocalDateTime.now();

    public MembroEquipe() {
    }

    public MembroEquipe(Usuario usuario, Estabelecimento estabelecimento) {
        this.usuario = usuario;
        this.estabelecimento = estabelecimento;
    }
}
