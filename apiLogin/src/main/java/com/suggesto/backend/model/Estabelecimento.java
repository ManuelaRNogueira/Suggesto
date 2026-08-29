package com.suggesto.backend.model;

import lombok.Data;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "estabelecimento")
@Data 
public class Estabelecimento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_estabelecimento")
    private long idEstabelecimento;

    @Column(name = "ativo")
    private Integer ativo = 1;

    @Column(name = "nome_estabelecimento", nullable = false)
    private String nome;

    @Column(name = "cnpj", nullable = false, unique = true)
    private String cnpj;

    @Column(name = "categoria", nullable = false)
    private String categoria;

    @Column(name = "telefone")
    private String telefone;

    @Column(name = "id_gerente", nullable = false)
    private long idGerente;

    @Column(name = "codigo_acesso", unique = true, length = 12)
    private String codigoAcesso;

    @Column(name = "cep", nullable = false, length = 9)
    private String cep;

    @Column(name = "estado", nullable = false, length = 2)
    private String estado;

    @Column(name = "cidade", nullable = false, length = 100)
    private String cidade;

    @Column(name = "bairro", nullable = false, length = 100)
    private String bairro;

    @Column(name = "rua", nullable = false, length = 150)
    private String rua;

    @Column(name = "numero", nullable = false, length = 20)
    private String numero;

    @Column(name = "complemento", length = 100)
    private String complemento;

    @Column(name = "horario_funcionamento", length = 150)
    private String horarioFuncionamento;

    // Texto livre que o admin escreve sobre o local — alimenta a aba "Sobre" do site.
    @Column(name = "sobre", columnDefinition = "TEXT")
    private String sobre;

    private String fotoPath;

    // Coordenadas geocodificadas a partir do endereço (ver GeocodificacaoService)
    // — preenchidas automaticamente no cadastro, ou pelo endpoint de backfill
    // pros estabelecimentos que já existiam antes desse campo. Nulas até lá:
    // "perto de você" na Home simplesmente ignora quem ainda não tem.
    @Column(name = "lat")
    private Double lat;

    @Column(name = "lng")
    private Double lng;

    // Quando o estabelecimento foi cadastrado — usado pra saber quem é "novo"
    // na página de notificações do cliente (ver notificacoesCli.js). Nulo pros
    // que já existiam antes desse campo (ver adicionar_data_cadastro.sql).
    @Column(name = "data_cadastro")
    private LocalDateTime dataCadastro;

    // Calculados a partir das avaliações, não persistidos no banco.
    @Transient
    private Double mediaAvaliacoes;

    @Transient
    private Long totalAvaliacoes;

    
    public String getFotoPath() {
        if (fotoPath == null || fotoPath.isBlank()) {
            return fotoPath;
        }
        String limpo = fotoPath.replace('\\', '/').trim();
        if ((limpo.startsWith("http://") || limpo.startsWith("https://")) && !limpo.contains("/uploads/")) {
            return limpo;
        }
        if (limpo.contains(":/") || limpo.startsWith("/")) {
            int idx = limpo.lastIndexOf("/uploads/");
            if (idx >= 0) {
                return limpo.substring(idx + "/uploads/".length());
            }
            int barra = limpo.lastIndexOf('/');
            return barra >= 0 ? limpo.substring(barra + 1) : limpo;
        }
        if (limpo.startsWith("uploads/")) {
            return limpo.substring("uploads/".length());
        }
        return limpo;
    }

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
        if (limpo.contains(":/")) {
            int idx = limpo.lastIndexOf("/uploads/");
            if (idx >= 0) {
                limpo = limpo.substring(idx + "/uploads/".length());
            } else {
                int barra = limpo.lastIndexOf('/');
                limpo = barra >= 0 ? limpo.substring(barra + 1) : limpo;
            }
        }
        if (limpo.startsWith("uploads/")) {
            limpo = limpo.substring("uploads/".length());
        }
        this.fotoPath = limpo;
    }

    public String getSobre() {
        return sobre;
    }

    public void setSobre(String sobre) {
        this.sobre = sobre;
    }

// Adicione estes métodos aqui no finalzinho!
    public Integer getAtivo() {
        return ativo;
    }

    public void setAtivo(Integer ativo) {
        this.ativo = ativo;
    }




}