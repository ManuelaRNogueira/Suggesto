package com.suggesto.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "categoria")
public class Categoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCategoria;

    private String nomeCategoria;

    // TODOS = aparece pra qualquer tipo de estabelecimento; FISICO = só quem tem espaço
    // físico visitado pelo cliente; COMIDA = só quem serve comida/bebida.
    // Ver CategoriaController pra a regra de quais tipos de estabelecimento caem em cada grupo.
    private String escopo;

    public Long getIdCategoria() {
        return idCategoria;
    }

    public void setIdCategoria(Long idCategoria) {
        this.idCategoria = idCategoria;
    }

    public String getNomeCategoria() {
        return nomeCategoria;
    }

    public void setNomeCategoria(String nomeCategoria) {
        this.nomeCategoria = nomeCategoria;
    }

    public String getEscopo() {
        return escopo;
    }

    public void setEscopo(String escopo) {
        this.escopo = escopo;
    }
}
