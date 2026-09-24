package com.suggesto.backend.service;

import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.model.Visita;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.repository.VisitaRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

import java.time.LocalDateTime;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

// Roda contra um H2 em memória (o @DataJpaTest troca o MySQL sozinho). As
// fórmulas dependem de consultas agregadas de verdade, por isso não são
// testadas com mocks (ver AvaliacaoServiceTest pros outros casos do service).
@DataJpaTest
@Import(ReputacaoService.class)
class ReputacaoServiceTest {

    @Autowired
    private ReputacaoService reputacaoService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private VisitaRepository visitaRepository;

    private Usuario criarUsuario(String username) {
        Usuario u = new Usuario();
        u.setUsername(username);
        return usuarioRepository.save(u);
    }

    private Estabelecimento criarEstabelecimento(String cnpj) {
        Estabelecimento e = new Estabelecimento();
        e.setNome("Bar");
        e.setCnpj(cnpj);
        e.setCategoria("bar");
        e.setIdGerente(1L);
        e.setCep("11111-111");
        e.setEstado("SP");
        e.setCidade("Campinas");
        e.setBairro("Centro");
        e.setRua("Rua X");
        e.setNumero("10");
        return estabelecimentoRepository.save(e);
    }

    private Visita criarVisita(Usuario usuario, Estabelecimento estab) {
        Visita v = new Visita();
        v.setUsuario(usuario);
        v.setEstabelecimento(estab);
        v.setDataCheckin(LocalDateTime.now());
        v.setMetodo(Visita.QR);
        return visitaRepository.save(v);
    }

    private void criarAvaliacao(Estabelecimento estab, Usuario usuario, String status, Visita visita) {
        Avaliacao a = new Avaliacao();
        a.setEstabelecimento(estab);
        a.setUsuario(usuario);
        a.setStatus(status);
        a.setNota(5);
        a.setDataAvaliacao(LocalDateTime.now());
        a.setVisita(visita);
        avaliacaoRepository.save(a);
    }

    private void criarAvaliacaoComReacao(Estabelecimento estab, String status,
            LocalDateTime dataAvaliacao, LocalDateTime dataDecisao, String resposta, LocalDateTime dataResposta) {
        Avaliacao a = new Avaliacao();
        a.setEstabelecimento(estab);
        a.setStatus(status);
        a.setNota(5);
        a.setDataAvaliacao(dataAvaliacao);
        a.setDataDecisao(dataDecisao);
        a.setResposta(resposta);
        a.setDataResposta(dataResposta);
        avaliacaoRepository.save(a);
    }

    // ── Confiabilidade (cliente) ──────────────────────────────────────────

    @Test
    void confiabilidadeConsideraSoAvaliacoesComVisita() {
        Usuario cliente = criarUsuario("cliente1");
        Estabelecimento estab = criarEstabelecimento("111");

        criarAvaliacao(estab, cliente, "aceita", criarVisita(cliente, estab));
        criarAvaliacao(estab, cliente, "aceita", criarVisita(cliente, estab));
        criarAvaliacao(estab, cliente, "recusada", criarVisita(cliente, estab));

        Map<String, Object> rep = reputacaoService.calcularConfiabilidade(cliente.getId());

        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat(componentes.get("aceitas")).isEqualTo(2L);
        assertThat(componentes.get("recusadas")).isEqualTo(1L);
        assertThat(componentes.get("decididas")).isEqualTo(3L);
        assertThat(rep.get("total")).isEqualTo(3L);
        assertThat(rep.get("pontuacao")).isEqualTo(67); // round(100*2/3)
        assertThat(rep.get("rotulo")).isNull();
    }

    @Test
    void menosDeTresDecididasResultaEmNovo() {
        Usuario cliente = criarUsuario("cliente2");
        Estabelecimento estab = criarEstabelecimento("222");

        criarAvaliacao(estab, cliente, "aceita", criarVisita(cliente, estab));

        Map<String, Object> rep = reputacaoService.calcularConfiabilidade(cliente.getId());

        assertThat(rep.get("pontuacao")).isNull();
        assertThat(rep.get("rotulo")).isEqualTo("Novo");
    }

    @Test
    void pendentesNaoContamNaConfiabilidade() {
        Usuario cliente = criarUsuario("cliente3");
        Estabelecimento estab = criarEstabelecimento("333");

        criarAvaliacao(estab, cliente, "aceita", criarVisita(cliente, estab));
        criarAvaliacao(estab, cliente, "aceita", criarVisita(cliente, estab));
        criarAvaliacao(estab, cliente, "pendente", criarVisita(cliente, estab));

        Map<String, Object> rep = reputacaoService.calcularConfiabilidade(cliente.getId());

        // Só 2 decididas (a pendente fica de fora): continua "Novo".
        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat(componentes.get("decididas")).isEqualTo(2L);
        assertThat(rep.get("rotulo")).isEqualTo("Novo");
    }

    @Test
    void avaliacaoSemVisitaNaoMudaConfiabilidadeNemParaCimaNemParaBaixo() {
        Usuario cliente = criarUsuario("cliente4");
        Estabelecimento estab = criarEstabelecimento("444");

        // Avaliações antigas, sem visita vinculada.
        criarAvaliacao(estab, cliente, "aceita", null);
        criarAvaliacao(estab, cliente, "aceita", null);
        criarAvaliacao(estab, cliente, "recusada", null);

        Map<String, Object> rep = reputacaoService.calcularConfiabilidade(cliente.getId());

        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat(componentes.get("decididas")).isEqualTo(0L);
        assertThat(rep.get("pontuacao")).isNull();
        assertThat(rep.get("rotulo")).isEqualTo("Novo");
    }

    // ── Transparência (estabelecimento) ───────────────────────────────────

    @Test
    void transparenciaComDadosConhecidos() {
        Estabelecimento estab = criarEstabelecimento("555");
        LocalDateTime t = LocalDateTime.now().minusDays(1);

        // Aceita, reagiu em 1h.
        criarAvaliacaoComReacao(estab, "aceita", t, t.plusHours(1), null, null);
        // Recusada, reagiu em 1h.
        criarAvaliacaoComReacao(estab, "recusada", t, t.plusHours(1), null, null);
        // Pendente, mas respondida em 2h (conta como resposta e como reação).
        criarAvaliacaoComReacao(estab, "pendente", t, null, "Obrigado!", t.plusHours(2));
        // Duas pendentes sem nenhuma reação.
        criarAvaliacaoComReacao(estab, "pendente", t, null, null, null);
        criarAvaliacaoComReacao(estab, "pendente", t, null, null, null);

        Map<String, Object> rep = reputacaoService.calcularTransparencia(estab.getIdEstabelecimento());

        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat(rep.get("total")).isEqualTo(5L);
        assertThat(componentes.get("respostas")).isEqualTo(3L); // aceita + recusada + a respondida
        assertThat(componentes.get("recusas")).isEqualTo(1L);
        assertThat(componentes.get("decididas")).isEqualTo(2L); // pendentes não entram
        assertThat((double) componentes.get("taxaResposta")).isEqualTo(0.6);
        assertThat((double) componentes.get("taxaRecusa")).isEqualTo(0.5);
        assertThat((double) componentes.get("agilidade")).isEqualTo(1.0); // média bem abaixo de 48h
        assertThat(rep.get("pontuacao")).isEqualTo(64); // round(40*0.6 + 40*0.5 + 20*1)
        assertThat(rep.get("rotulo")).isNull();
    }

    @Test
    void menosDeCincoAvaliacoesResultaSemDadosSuficientes() {
        Estabelecimento estab = criarEstabelecimento("666");
        LocalDateTime t = LocalDateTime.now();
        criarAvaliacaoComReacao(estab, "aceita", t, t.plusHours(1), null, null);
        criarAvaliacaoComReacao(estab, "aceita", t, t.plusHours(1), null, null);
        criarAvaliacaoComReacao(estab, "pendente", t, null, null, null);

        Map<String, Object> rep = reputacaoService.calcularTransparencia(estab.getIdEstabelecimento());

        assertThat(rep.get("pontuacao")).isNull();
        assertThat(rep.get("rotulo")).isEqualTo("Sem dados suficientes");
    }

    @Test
    void agilidadeMaximaAte48Horas() {
        Estabelecimento estab = criarEstabelecimento("777");
        LocalDateTime t = LocalDateTime.now().minusDays(3);
        for (int i = 0; i < 5; i++) {
            criarAvaliacaoComReacao(estab, "aceita", t, t.plusHours(48), null, null);
        }

        Map<String, Object> rep = reputacaoService.calcularTransparencia(estab.getIdEstabelecimento());
        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat((double) componentes.get("agilidade")).isEqualTo(1.0);
    }

    @Test
    void agilidadeZeradaComQuatorzeDiasOuMais() {
        Estabelecimento estab = criarEstabelecimento("888");
        LocalDateTime t = LocalDateTime.now().minusDays(20);
        for (int i = 0; i < 5; i++) {
            criarAvaliacaoComReacao(estab, "aceita", t, t.plusDays(14), null, null);
        }

        Map<String, Object> rep = reputacaoService.calcularTransparencia(estab.getIdEstabelecimento());
        Map<?, ?> componentes = (Map<?, ?>) rep.get("componentes");
        assertThat((double) componentes.get("agilidade")).isEqualTo(0.0);
    }
}
