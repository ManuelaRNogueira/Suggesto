package com.suggesto.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "recompensa")
public class Recompensa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    @Column(columnDefinition = "TEXT")
    private String descricao;

    @Column(name = "custo_pontos", nullable = false)
    private Integer custoPontos;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "id_estabelecimento", nullable = false)
    private Estabelecimento estabelecimento;

    // Foto própria da recompensa. Quando fica nula, o cliente cai na foto do
    // estabelecimento (ver lojapontosCli.js).
    @Column(name = "foto_path")
    private String fotoPath;

    // Quando a recompensa foi cadastrada — usado pra saber quem é "nova" na
    // página de notificações do cliente (ver notificacoesCli.js). Nula pras
    // que já existiam antes desse campo (ver adicionar_data_cadastro.sql).
    @Column(name = "data_cadastro")
    private LocalDateTime dataCadastro;

    public LocalDateTime getDataCadastro() {
        return dataCadastro;
    }

    public void setDataCadastro(LocalDateTime dataCadastro) {
        this.dataCadastro = dataCadastro;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public Integer getCustoPontos() {
        return custoPontos;
    }

    public void setCustoPontos(Integer custoPontos) {
        this.custoPontos = custoPontos;
    }

    public Estabelecimento getEstabelecimento() {
        return estabelecimento;
    }

    public void setEstabelecimento(Estabelecimento estabelecimento) {
        this.estabelecimento = estabelecimento;
    }

    public String getFotoPath() {
        return fotoPath;
    }

    // Guarda sempre só o nome do arquivo, igual ao Estabelecimento: o cliente
    // monta a URL prefixando /uploads/.
    public void setFotoPath(String fotoPath) {
        if (fotoPath == null || fotoPath.isBlank()) {
            this.fotoPath = fotoPath;
            return;
        }

        String limpo = fotoPath.replace('\\', '/').trim();
        if ((limpo.startsWith("http://") || limpo.startsWith("https://")) && !limpo.contains("/uploads/")) {
            this.fotoPath = limpo;
            return;
        }
        int idx = limpo.lastIndexOf("/uploads/");
        if (idx >= 0) {
            limpo = limpo.substring(idx + "/uploads/".length());
        } else if (limpo.startsWith("uploads/")) {
            limpo = limpo.substring("uploads/".length());
        }
        this.fotoPath = limpo;
    }
}
