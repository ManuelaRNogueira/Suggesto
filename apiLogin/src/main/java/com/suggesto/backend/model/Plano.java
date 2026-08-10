package com.suggesto.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "plano")
public class Plano {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nome", nullable = false, unique = true)
    private String nome;

    @Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;

    @Column(name = "preco")
    private Double preco;

    // Limites do plano. null = ilimitado (é assim que "Empresarial" fica sem teto).
    @Column(name = "limite_estabelecimentos")
    private Integer limiteEstabelecimentos;

    @Column(name = "limite_feedbacks_mes")
    private Integer limiteFeedbacksMes;

    @Column(name = "limite_admins")
    private Integer limiteAdmins;

    @Column(name = "permite_relatorios")
    private Boolean permiteRelatorios = Boolean.TRUE;

    @Column(name = "permite_exportacao")
    private Boolean permiteExportacao = Boolean.TRUE;

    @Column(name = "permite_recompensas")
    private Boolean permiteRecompensas = Boolean.TRUE;

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

    public Double getPreco() {
        return preco;
    }

    public void setPreco(Double preco) {
        this.preco = preco;
    }

    public Integer getLimiteEstabelecimentos() {
        return limiteEstabelecimentos;
    }

    public void setLimiteEstabelecimentos(Integer limiteEstabelecimentos) {
        this.limiteEstabelecimentos = limiteEstabelecimentos;
    }

    public Integer getLimiteFeedbacksMes() {
        return limiteFeedbacksMes;
    }

    public void setLimiteFeedbacksMes(Integer limiteFeedbacksMes) {
        this.limiteFeedbacksMes = limiteFeedbacksMes;
    }

    public Integer getLimiteAdmins() {
        return limiteAdmins;
    }

    public void setLimiteAdmins(Integer limiteAdmins) {
        this.limiteAdmins = limiteAdmins;
    }

    public Boolean getPermiteRelatorios() {
        return permiteRelatorios == null || permiteRelatorios;
    }

    public void setPermiteRelatorios(Boolean permiteRelatorios) {
        this.permiteRelatorios = permiteRelatorios;
    }

    public Boolean getPermiteExportacao() {
        return permiteExportacao == null || permiteExportacao;
    }

    public void setPermiteExportacao(Boolean permiteExportacao) {
        this.permiteExportacao = permiteExportacao;
    }

    public Boolean getPermiteRecompensas() {
        return permiteRecompensas == null || permiteRecompensas;
    }

    public void setPermiteRecompensas(Boolean permiteRecompensas) {
        this.permiteRecompensas = permiteRecompensas;
    }
}
