package com.suggesto.backend.service;

import com.suggesto.backend.config.UsuarioConvidadoSeeder;
import com.suggesto.backend.dto.AvaliacaoRequestDTO;
import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.CategoriaRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.MembroEquipeRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class AvaliacaoService {

    private static final int PONTOS_SUGESTAO_ACEITA = 500;
    private static final Set<String> STATUS_ACEITOS = Set.of(
            "aceita", "aceito", "resolvida", "resolvido", "implementado", "implementada"
    );
    private static final Set<String> STATUS_RECUSADOS = Set.of("recusada", "recusado");

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private MembroEquipeRepository membroEquipeRepository;

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private PlanoService planoService;

    // Cria uma nova sugestão/crítica/elogio. Se não veio um usuário logado
    // (alguém dando feedback sem estar cadastrado), usa a conta "convidado"
    // padrão do sistema pra não deixar a avaliação sem dono.
    @Transactional
    public void registrarNovaAvaliacao(AvaliacaoRequestDTO dto) {
        Usuario usuario = dto.getIdUsuario() != null
                ? usuarioRepository.findById(dto.getIdUsuario())
                        .orElseThrow(() -> new RuntimeException("Usuário não encontrado. ID: " + dto.getIdUsuario()))
                : usuarioRepository.findByUsername(UsuarioConvidadoSeeder.USERNAME_CONVIDADO)
                        .orElseThrow(() -> new RuntimeException("Usuário convidado não encontrado."));

        Estabelecimento est = estabelecimentoRepository.findById(dto.getIdEstabelecimento())
                .orElseThrow(() -> new RuntimeException("Estabelecimento não encontrado. ID: " + dto.getIdEstabelecimento()));

        Categoria categoria = categoriaRepository.findById(dto.getIdCategoria())
                .orElseThrow(() -> new RuntimeException("Categoria não encontrada com o ID: " + dto.getIdCategoria()));

        // O plano do estabelecimento pode limitar quantos feedbacks ele recebe por mês.
        planoService.validarNovoFeedback(est);

        Avaliacao avaliacao = new Avaliacao();
        avaliacao.setTipo(dto.getTipo());
        avaliacao.setNota(dto.getNota());
        avaliacao.setComentario(dto.getComentario());
        avaliacao.setDataAvaliacao(LocalDateTime.now());
        avaliacao.setStatus("pendente");
        avaliacao.setEstabelecimento(est);
        avaliacao.setCategoria(categoria);
        avaliacao.setUsuario(usuario);

        avaliacaoRepository.save(avaliacao);
    }

    // Muda o status da sugestão (pendente → aceita/recusada) e, se essa
    // mudança for a primeira vez que ela vira "aceita", credita os pontos pro autor.
    @Transactional
    public Avaliacao atualizarStatus(Long idAvaliacao, String novoStatus) {
        Avaliacao avaliacao = avaliacaoRepository.findById(idAvaliacao)
                .orElseThrow(() -> new RuntimeException("Sugestão não encontrada."));

        String statusAnterior = avaliacao.getStatus();
        String statusNormalizado = normalizarStatus(novoStatus);
        avaliacao.setStatus(statusNormalizado);

        if (deveCreditarPontos(statusAnterior, statusNormalizado)) {
            Usuario autor = avaliacao.getUsuario();
            if (autor != null && autor.getId() != null) {
                usuarioRepository.creditarPontos(autor.getId(), PONTOS_SUGESTAO_ACEITA);
            }
        }

        return avaliacaoRepository.save(avaliacao);
    }

    // Só um administrador do próprio estabelecimento pode responder à sugestão:
    // ou é o gerente principal, ou faz parte da equipe vinculada a ele.
    @Transactional
    public Avaliacao responder(Long idAvaliacao, Long idAdmin, String texto) {
        if (texto == null || texto.isBlank()) {
            throw new IllegalArgumentException("A resposta não pode ficar vazia.");
        }

        Avaliacao avaliacao = avaliacaoRepository.findById(idAvaliacao)
                .orElseThrow(() -> new IllegalArgumentException("Sugestão não encontrada."));

        Estabelecimento alvo = avaliacao.getEstabelecimento();
        if (alvo == null) {
            throw new IllegalArgumentException("Sugestão sem estabelecimento vinculado.");
        }

        Usuario admin = usuarioRepository.findById(idAdmin)
                .orElseThrow(() -> new IllegalArgumentException("Administrador não encontrado."));

        boolean ehGerente = alvo.getIdGerente() == idAdmin;
        boolean ehDaEquipe = membroEquipeRepository
                .existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(idAdmin, alvo.getIdEstabelecimento());

        if (!ehGerente && !ehDaEquipe) {
            throw new SecurityException("Você não faz parte da equipe deste estabelecimento.");
        }

        avaliacao.setResposta(texto.trim());
        avaliacao.setDataResposta(LocalDateTime.now());
        avaliacao.setRespondidoPor(admin.getNome());

        return avaliacaoRepository.save(avaliacao);
    }

    // O cliente só apaga a própria sugestão enquanto ela está pendente. Depois de
    // aprovada ela já creditou pontos, e depois de recusada/respondida apagaria
    // junto o que o estabelecimento escreveu.
    @Transactional
    public void excluirDoUsuario(Long idAvaliacao, Long idUsuario) {
        if (idUsuario == null) {
            throw new IllegalArgumentException("Informe o usuário dono da sugestão.");
        }

        Avaliacao avaliacao = avaliacaoRepository.findById(idAvaliacao)
                .orElseThrow(() -> new IllegalArgumentException("Sugestão não encontrada."));

        Usuario autor = avaliacao.getUsuario();
        if (autor == null || autor.getId() == null || !autor.getId().equals(idUsuario)) {
            throw new SecurityException("Você só pode excluir as suas próprias sugestões.");
        }

        if (!isStatusPendente(avaliacao.getStatus())) {
            throw new IllegalStateException(
                    "O estabelecimento já respondeu esta sugestão, então ela não pode mais ser excluída.");
        }

        avaliacaoRepository.delete(avaliacao);
    }

    private boolean isStatusPendente(String status) {
        return !isStatusAceito(status) && !isStatusRecusado(status);
    }

    private boolean isStatusRecusado(String status) {
        if (status == null || status.isBlank()) {
            return false;
        }
        return STATUS_RECUSADOS.contains(status.trim().toLowerCase(Locale.ROOT));
    }

    private String normalizarStatus(String status) {
        if (status == null || status.isBlank()) {
            throw new IllegalArgumentException("Status inválido.");
        }
        return status.trim().toUpperCase(Locale.ROOT);
    }

    // Os pontos só são creditados no momento exato em que a sugestão passa de
    // "pendente" pra "aceita" — é um carimbo que só é dado uma vez. Editar a
    // sugestão depois não credita pontos de novo.
    private boolean deveCreditarPontos(String statusAnterior, String statusNovo) {
        if (!isStatusAceito(statusNovo)) {
            return false;
        }
        return !isStatusAceito(statusAnterior);
    }

    private boolean isStatusAceito(String status) {
        if (status == null || status.isBlank()) {
            return false;
        }
        return STATUS_ACEITOS.contains(status.trim().toLowerCase(Locale.ROOT));
    }

    // Preenche a média/contagem de avaliações (calculadas, não persistidas) de
    // cada estabelecimento. Extraído de EstabelecimentoController pra também
    // ser usado por LocalSalvoController — antes só o endpoint /estabelecimentos
    // chamava isso, e /locais-salvos/usuario/{id} devolvia mediaAvaliacoes
    // sempre null pros mesmos estabelecimentos.
    public void aplicarMediasDeAvaliacao(List<Estabelecimento> estabelecimentos) {
        Map<Long, Object[]> medias = new HashMap<>();
        for (Object[] linha : avaliacaoRepository.calcularMediaEContagemPorEstabelecimento()) {
            medias.put((Long) linha[0], linha);
        }

        for (Estabelecimento estab : estabelecimentos) {
            Object[] linha = medias.get(estab.getIdEstabelecimento());
            if (linha != null) {
                estab.setMediaAvaliacoes((Double) linha[1]);
                estab.setTotalAvaliacoes((Long) linha[2]);
            }
        }
    }
}
