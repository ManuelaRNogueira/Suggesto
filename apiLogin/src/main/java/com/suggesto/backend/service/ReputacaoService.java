package com.suggesto.backend.service;

import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

// Confiabilidade (cliente) e Transparência (estabelecimento) são sempre
// recalculadas na hora a partir do histórico de avaliações — igual às
// conquistas, não existe tabela nem coluna guardando essas pontuações.
@Service
public class ReputacaoService {

    private static final Set<String> STATUS_ACEITOS = Set.of(
            "aceita", "aceito", "resolvida", "resolvido", "implementado", "implementada"
    );
    private static final Set<String> STATUS_RECUSADOS = Set.of("recusada", "recusado");

    private static final int MIN_DECIDIDAS_CONFIABILIDADE = 3;
    private static final int MIN_AVALIACOES_TRANSPARENCIA = 5;
    private static final double AGILIDADE_HORAS_MAXIMAS = 48;
    private static final double AGILIDADE_HORAS_LIMITE = 14 * 24;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    public Map<String, Object> calcularConfiabilidade(Long idUsuario) {
        if (!usuarioRepository.existsById(idUsuario)) {
            throw new IllegalArgumentException("Usuário não encontrado.");
        }
        return calcularConfiabilidadeEmLote(List.of(idUsuario)).get(idUsuario);
    }

    // Uma consulta só pra todo mundo da lista, em vez de uma por autor — é o
    // que a listagem de sugestões do painel usa pra mostrar a Confiabilidade
    // ao lado do nível de cada autor.
    public Map<Long, Map<String, Object>> calcularConfiabilidadeEmLote(List<Long> idsUsuarios) {
        Map<Long, Map<String, Object>> resultado = new LinkedHashMap<>();
        if (idsUsuarios == null || idsUsuarios.isEmpty()) {
            return resultado;
        }

        List<Long> idsUnicos = idsUsuarios.stream().distinct().toList();
        Map<Long, long[]> contagens = new HashMap<>(); // [aceitas, recusadas]
        for (Long id : idsUnicos) {
            contagens.put(id, new long[2]);
        }

        for (Object[] linha : avaliacaoRepository.buscarStatusComVisitaPorUsuarios(idsUnicos)) {
            Long idUsuario = (Long) linha[0];
            String status = (String) linha[1];
            long[] contagem = contagens.get(idUsuario);
            if (contagem == null) {
                continue;
            }
            if (STATUS_ACEITOS.contains(status)) {
                contagem[0]++;
            } else if (STATUS_RECUSADOS.contains(status)) {
                contagem[1]++;
            }
        }

        for (Long id : idsUnicos) {
            long[] contagem = contagens.get(id);
            long aceitas = contagem[0];
            long recusadas = contagem[1];
            long decididas = aceitas + recusadas;

            Map<String, Object> componentes = new LinkedHashMap<>();
            componentes.put("aceitas", aceitas);
            componentes.put("recusadas", recusadas);
            componentes.put("decididas", decididas);

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("componentes", componentes);
            item.put("total", decididas);

            if (decididas < MIN_DECIDIDAS_CONFIABILIDADE) {
                item.put("pontuacao", null);
                item.put("rotulo", "Novo");
            } else {
                double aceitacao = (double) aceitas / decididas;
                item.put("pontuacao", (int) Math.round(100 * aceitacao));
                item.put("rotulo", null);
            }
            resultado.put(id, item);
        }
        return resultado;
    }

    public Map<String, Object> calcularTransparencia(Long idEstabelecimento) {
        if (!estabelecimentoRepository.existsById(idEstabelecimento)) {
            throw new IllegalArgumentException("Estabelecimento não encontrado.");
        }

        List<Object[]> linhas = avaliacaoRepository.buscarDadosReputacaoEstabelecimento(idEstabelecimento);

        long total = linhas.size();
        long respostas = 0;
        long recusadas = 0;
        long decididas = 0;
        double somaHorasReacao = 0;
        long reagidas = 0;

        for (Object[] linha : linhas) {
            String status = linha[0] == null ? "" : ((String) linha[0]).trim().toLowerCase(Locale.ROOT);
            LocalDateTime dataAvaliacao = (LocalDateTime) linha[1];
            LocalDateTime dataResposta = (LocalDateTime) linha[2];
            LocalDateTime dataDecisao = (LocalDateTime) linha[3];
            String resposta = (String) linha[4];

            boolean saiuDePendente = STATUS_ACEITOS.contains(status) || STATUS_RECUSADOS.contains(status);
            boolean temRespostaEscrita = resposta != null && !resposta.isBlank();
            if (temRespostaEscrita || saiuDePendente) {
                respostas++;
            }
            if (STATUS_RECUSADOS.contains(status)) {
                recusadas++;
            }
            if (saiuDePendente) {
                decididas++;
            }

            LocalDateTime primeiraReacao = primeiraData(dataResposta, dataDecisao);
            if (primeiraReacao != null && dataAvaliacao != null) {
                somaHorasReacao += Duration.between(dataAvaliacao, primeiraReacao).toMinutes() / 60.0;
                reagidas++;
            }
        }

        double taxaResposta = total == 0 ? 0 : (double) respostas / total;
        double taxaRecusa = decididas == 0 ? 0 : (double) recusadas / decididas;
        double agilidade = calcularAgilidade(reagidas == 0 ? null : somaHorasReacao / reagidas);

        Map<String, Object> componentes = new LinkedHashMap<>();
        componentes.put("respostas", respostas);
        componentes.put("recusas", recusadas);
        componentes.put("decididas", decididas);
        componentes.put("taxaResposta", taxaResposta);
        componentes.put("taxaRecusa", taxaRecusa);
        componentes.put("agilidade", agilidade);

        Map<String, Object> item = new LinkedHashMap<>();
        item.put("componentes", componentes);
        item.put("total", total);

        if (total < MIN_AVALIACOES_TRANSPARENCIA) {
            item.put("pontuacao", null);
            item.put("rotulo", "Sem dados suficientes");
        } else {
            double pontuacao = 40 * taxaResposta + 40 * (1 - taxaRecusa) + 20 * agilidade;
            item.put("pontuacao", (int) Math.round(pontuacao));
            item.put("rotulo", null);
        }
        return item;
    }

    private LocalDateTime primeiraData(LocalDateTime a, LocalDateTime b) {
        if (a == null) {
            return b;
        }
        if (b == null) {
            return a;
        }
        return a.isBefore(b) ? a : b;
    }

    // 1 até 48h, caindo linearmente até 0 em 14 dias. Sem nenhuma reação
    // registrada ainda, conta como o pior caso (0), pra não inflar a nota de
    // quem simplesmente não respondeu nada.
    private double calcularAgilidade(Double mediaHoras) {
        if (mediaHoras == null) {
            return 0;
        }
        if (mediaHoras <= AGILIDADE_HORAS_MAXIMAS) {
            return 1;
        }
        if (mediaHoras >= AGILIDADE_HORAS_LIMITE) {
            return 0;
        }
        return 1 - (mediaHoras - AGILIDADE_HORAS_MAXIMAS) / (AGILIDADE_HORAS_LIMITE - AGILIDADE_HORAS_MAXIMAS);
    }
}
