package com.suggesto.backend.service;

import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.util.NivelUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminService {

    private static final Set<String> STATUS_IMPLEMENTADO = Set.of(
            "aceita", "aceito", "resolvida", "resolvido", "implementado", "implementada"
    );
    private static final Set<String> STATUS_RECUSADO = Set.of("recusada", "recusado");

    private static final int MESES_PADRAO = 6;
    private static final int MESES_MAXIMO = 24;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private ResgateRepository resgateRepository;

    public Map<String, Object> obterMetricas(Long idGerente, Integer meses) {
        return obterMetricas(idGerente, meses, null);
    }

    public Map<String, Object> obterMetricas(Long idGerente, Integer meses, Long idEstabelecimento) {
        int janela = (meses == null) ? MESES_PADRAO : Math.max(1, Math.min(meses, MESES_MAXIMO));
        List<Estabelecimento> estabelecimentos = resolverEstabelecimentos(idGerente);

        if (idEstabelecimento != null) {
            estabelecimentos = estabelecimentos.stream()
                    .filter(e -> e.getIdEstabelecimento() == idEstabelecimento)
                    .collect(Collectors.toList());
        }

        List<Long> ids = estabelecimentos.stream()
                .map(Estabelecimento::getIdEstabelecimento)
                .collect(Collectors.toList());

        List<Avaliacao> sugestoes = buscarSugestoesPorEstabelecimentos(idGerente, ids);

        // Semana atual = da segunda-feira 00:00 até agora, não os últimos 7 dias corridos.
        LocalDateTime inicioSemanaAtual = LocalDate.now().with(DayOfWeek.MONDAY).atStartOfDay();

        int pendentes = 0;
        int implementados = 0;
        int recusados = 0;
        int novasSemana = 0;
        Map<String, Integer> porCategoria = new LinkedHashMap<>();

        for (Avaliacao a : sugestoes) {
            String grupo = classificarStatus(a.getStatus());
            switch (grupo) {
                case "implementado" -> implementados++;
                case "recusado" -> recusados++;
                default -> pendentes++;
            }
            if (a.getDataAvaliacao() != null && !a.getDataAvaliacao().isBefore(inicioSemanaAtual)) {
                novasSemana++;
            }
            porCategoria.merge(classificarTipo(a.getTipo()), 1, Integer::sum);
        }

        long totalAdmins = idGerente == null
                ? usuarioRepository.countByTipoUsuario(TipoUsuario.Administrador)
                : usuarioRepository.countByEstabelecimento_IdGerente(idGerente);

        Map<String, Object> metricas = new LinkedHashMap<>();
        metricas.put("totalUsuarios", usuarioRepository.countByTipoUsuario(TipoUsuario.Cliente));
        metricas.put("totalAdmins", totalAdmins);
        metricas.put("totalSugestoes", sugestoes.size());
        metricas.put("totalResgates", resgateRepository.count());
        metricas.put("totalEstabelecimentos", estabelecimentos.size());
        metricas.put("novasSemana", novasSemana);
        metricas.put("pendentes", pendentes);
        metricas.put("implementados", implementados);
        metricas.put("recusados", recusados);
        metricas.put("porCategoria", porCategoria);
        metricas.put("meses", janela);
        metricas.put("sugestoesPorMes", calcularSugestoesPorMes(sugestoes, janela));
        metricas.put("sugestoesRecentes", sugestoes.stream()
                .filter(a -> a.getDataAvaliacao() != null && !a.getDataAvaliacao().isBefore(inicioSemanaAtual))
                .limit(8)
                .map(this::resumirSugestao)
                .collect(Collectors.toList()));

        return metricas;
    }

    public List<Map<String, Object>> listarSugestoes(Long idGerente) {
        List<Estabelecimento> estabelecimentos = resolverEstabelecimentos(idGerente);
        List<Long> ids = estabelecimentos.stream()
                .map(Estabelecimento::getIdEstabelecimento)
                .collect(Collectors.toList());

        List<Avaliacao> sugestoes = buscarSugestoesPorEstabelecimentos(idGerente, ids);

        return sugestoes.stream().map(this::resumirSugestao).collect(Collectors.toList());
    }

    // Só busca todas as avaliações do sistema quando não há filtro de gerente nenhum.
    // Quando há um idGerente (ou um estabelecimento específico selecionado) mas a lista de
    // estabelecimentos resultante está vazia, o resultado tem que ser vazio também —
    // nunca deve "vazar" sugestões de outros donos.
    private List<Avaliacao> buscarSugestoesPorEstabelecimentos(Long idGerente, List<Long> ids) {
        if (idGerente == null) {
            return avaliacaoRepository.findAllByOrderByDataAvaliacaoDesc();
        }
        if (ids.isEmpty()) {
            return List.of();
        }
        return avaliacaoRepository.findByEstabelecimentoIdEstabelecimentoInOrderByDataAvaliacaoDesc(ids);
    }

    public List<Map<String, Object>> listarUsuarios(Long idGerente) {
        List<Usuario> usuarios = idGerente == null
                ? usuarioRepository.findAllByOrderByNomeAsc()
                : usuarioRepository.findByEstabelecimento_IdGerenteOrderByNomeAsc(idGerente);

        return usuarios.stream()
                .map(this::resumirUsuario)
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> listarEstabelecimentos(Long idGerente) {
        // Aqui devolvemos ativos e inativos: o painel mostra a tag de situação.
        // As métricas continuam contando só os ativos.
        return resolverEstabelecimentosIncluindoInativos(idGerente).stream()
                .map(e -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("id", e.getIdEstabelecimento());
                    item.put("nome", e.getNome());
                    item.put("cidade", e.getCidade());
                    item.put("categoria", e.getCategoria());
                    item.put("ativo", e.getAtivo());
                    item.put("codigoAcesso", e.getCodigoAcesso());
                    // CORREÇÃO: Ajustado de countByEstabelecimento_IdEstabelecimento para countByEstabelecimentoIdEstabelecimento
                    item.put("totalSugestoes", avaliacaoRepository.countByEstabelecimentoIdEstabelecimento(e.getIdEstabelecimento()));
                    return item;
                })
                .collect(Collectors.toList());
    }

    private List<Estabelecimento> resolverEstabelecimentos(Long idGerente) {
        if (idGerente == null) {
            return estabelecimentoRepository.buscarTodosAtivos();
        }
        // Nunca cair para "todos os estabelecimentos" aqui: um gerente sem locais
        // vinculados deve ver uma lista vazia, não os locais de outros donos.
        return estabelecimentoRepository.buscarPorGerenteAtivos(idGerente);
    }

    private List<Estabelecimento> resolverEstabelecimentosIncluindoInativos(Long idGerente) {
        if (idGerente == null) {
            return estabelecimentoRepository.findAll();
        }
        return estabelecimentoRepository.findByIdGerente(idGerente);
    }

    private String classificarTipo(String tipo) {
        if (tipo == null || tipo.isBlank()) {
            return "Outro";
        }
        String t = tipo.trim().toLowerCase(Locale.ROOT);
        return switch (t) {
            case "sugestao" -> "Sugestão";
            case "critica" -> "Crítica";
            case "elogio" -> "Elogio";
            default -> tipo.trim();
        };
    }

    private String classificarStatus(String status) {
        if (status == null || status.isBlank()) {
            return "pendente";
        }
        String s = status.trim().toLowerCase(Locale.ROOT);
        if (STATUS_IMPLEMENTADO.contains(s)) return "implementado";
        if (STATUS_RECUSADO.contains(s)) return "recusado";
        return "pendente";
    }

    private List<Map<String, Object>> calcularSugestoesPorMes(List<Avaliacao> sugestoes, int meses) {
        List<Map<String, Object>> resultado = new ArrayList<>();
        LocalDateTime agora = LocalDateTime.now();

        for (int i = meses - 1; i >= 0; i--) {
            LocalDateTime inicio = agora.minusMonths(i).withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime fim = inicio.plusMonths(1);
            long count = sugestoes.stream()
                    .filter(a -> a.getDataAvaliacao() != null
                            && !a.getDataAvaliacao().isBefore(inicio)
                            && a.getDataAvaliacao().isBefore(fim))
                    .count();

            Map<String, Object> mes = new LinkedHashMap<>();
            mes.put("mes", inicio.format(DateTimeFormatter.ofPattern("MMM", new Locale("pt", "BR"))));
            mes.put("total", count);
            resultado.add(mes);
        }
        return resultado;
    }

    private Map<String, Object> resumirSugestao(Avaliacao a) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", a.getIdAvaliacao());
        item.put("comentario", a.getComentario());
        item.put("status", a.getStatus());
        item.put("statusUi", classificarStatus(a.getStatus()));
        item.put("nota", a.getNota());
        item.put("dataAvaliacao", a.getDataAvaliacao());
        item.put("categoria", a.getCategoria() != null ? a.getCategoria().getNomeCategoria() : null);
        item.put("autor", a.getUsuario() != null ? a.getUsuario().getNome() : null);
        item.put("autorId", a.getUsuario() != null ? a.getUsuario().getId() : null);
        // Nível do autor: define a prioridade de resposta e o selo mostrado na fila.
        Integer pontosAutor = a.getUsuario() != null ? a.getUsuario().getPontos() : 0;
        item.put("nivelAutor", NivelUtil.idNivel(pontosAutor));
        item.put("nivelAutorNome", NivelUtil.nomeNivel(pontosAutor));
        item.put("prioridade", NivelUtil.prioridade(pontosAutor));
        item.put("resposta", a.getResposta());
        item.put("respondidoPor", a.getRespondidoPor());
        item.put("dataResposta", a.getDataResposta());
        item.put("estabelecimento", a.getEstabelecimento() != null ? a.getEstabelecimento().getNome() : null);
        item.put("estabelecimentoId", a.getEstabelecimento() != null ? a.getEstabelecimento().getIdEstabelecimento() : null);
        return item;
    }

    private Map<String, Object> resumirUsuario(Usuario u) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", u.getId());
        item.put("nome", u.getNome());
        item.put("email", u.getEmail());
        item.put("telefone", u.getTelefone());
        item.put("cidade", u.getCidade());
        item.put("tipoUsuario", u.getTipoUsuario() != null ? u.getTipoUsuario().name() : null);
        item.put("cargo", u.getCargo());
        item.put("pontos", u.getPontos());
        item.put("plano", u.getPlano() != null ? u.getPlano().getNome() : null);
        item.put("principal", u.getEstabelecimento() != null && u.getEstabelecimento().getIdGerente() == u.getId());
        return item;
    }
}