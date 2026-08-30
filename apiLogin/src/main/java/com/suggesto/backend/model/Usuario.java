package com.suggesto.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.suggesto.backend.util.NivelUtil;
import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "usuario")
@Data
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_Usuario")
    private Long id;

    @Column(name = "Nome_Usuario")
    private String nome;

    @Column(name = "Username", unique = true, length = 30)
    private String username;

    @Column(name = "Email")
    private String email;

    @JsonIgnore
    @Column(name = "Senha")
    private String senha;

    @Enumerated(EnumType.STRING)
    @Column(name = "Tipo_Usuario")
    private TipoUsuario tipoUsuario;

    @Column(name = "Cargo")
    private String cargo;

    @Column(name = "CPF")
    private String cpf;

    @Column(name = "Telefone")
    private String telefone;

    @Column(name = "Cidade")
    private String cidade;

    // Cidade e estado do cliente vêm do CEP (mesma fonte usada no cadastro do
    // estabelecimento), para a busca por proximidade casar as duas pontas.
    @Column(name = "CEP", length = 9)
    private String cep;

    @Column(name = "Estado", length = 2)
    private String estado;

    @Column(name = "Foto_Url")
    private String fotoUrl;

    @Column(name = "pontos", nullable = false)
    private Integer pontos = 0;

    @ManyToOne
    @JoinColumn(name = "plano_id")
    private Plano plano;

    // O vínculo com estabelecimentos (dono e/ou funcionária de vários) agora
    // vive em MembroEquipe — uma pessoa não tem mais um único estabelecimento
    // fixo aqui (ver adicionar_membro_equipe.sql).

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

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public TipoUsuario getTipoUsuario() {
        return tipoUsuario;
    }

    public void setTipoUsuario(TipoUsuario tipoUsuario) {
        this.tipoUsuario = tipoUsuario;
    }

    public String getCargo() {
        return cargo;
    }

    public void setCargo(String cargo) {
        this.cargo = cargo;
    }

    public String getCpf() {
        return cpf;
    }

    public void setCpf(String cpf) {
        this.cpf = cpf;
    }

    public String getTelefone() {
        return telefone;
    }

    public void setTelefone(String telefone) {
        this.telefone = telefone;
    }

    public String getCidade() {
        return cidade;
    }

    public String getCep() {
        return cep;
    }

    public void setCep(String cep) {
        this.cep = cep;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public void setCidade(String cidade) {
        this.cidade = cidade;
    }

    public String getFotoUrl() {
        return fotoUrl;
    }

    public void setFotoUrl(String fotoUrl) {
        this.fotoUrl = fotoUrl;
    }

    public Plano getPlano() {
        return plano;
    }

    public void setPlano(Plano plano) {
        this.plano = plano;
    }

    public Integer getPontos() {
        return pontos != null ? pontos : 0;
    }

    public void setPontos(Integer pontos) {
        this.pontos = pontos != null ? Math.max(0, pontos) : 0;
    }

    // Derivados dos pontos — não persistidos, mas serializados no JSON para o
    // front não precisar recalcular a régua de níveis em cada tela.
    @Transient
    public String getNivel() {
        return NivelUtil.idNivel(getPontos());
    }

    @Transient
    public String getNivelNome() {
        return NivelUtil.nomeNivel(getPontos());
    }
}
