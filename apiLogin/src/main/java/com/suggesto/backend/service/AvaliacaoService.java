package com.suggesto.backend.service;

import com.suggesto.backend.dto.AvaliacaoRequestDTO;
import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.model.Categoria;
import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.CategoriaRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Set;

@Service
public class AvaliacaoService {

    private static final int PONTOS_SUGESTAO_ACEITA = 500;
    private static final Set<String> STATUS_ACEITOS = Set.of(
            "aceita", "aceito", "resolvida", "resolvido", "implementado", "implementada"
    );

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Transactional
    public void registrarNovaAvaliacao(AvaliacaoRequestDTO dto) {
        Usuario usuario = usuarioRepository.findById(dto.getIdUsuario())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado. ID: " + dto.getIdUsuario()));

        Estabelecimento est = estabelecimentoRepository.findById(dto.getIdEstabelecimento())
                .orElseThrow(() -> new RuntimeException("Estabelecimento não encontrado. ID: " + dto.getIdEstabelecimento()));

        Categoria categoria = categoriaRepository.findById(dto.getIdCategoria())
                .orElseThrow(() -> new RuntimeException("Categoria não encontrada com o ID: " + dto.getIdCategoria()));

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

    private String normalizarStatus(String status) {
        if (status == null || status.isBlank()) {
            throw new IllegalArgumentException("Status inválido.");
        }
        return status.trim().toUpperCase(Locale.ROOT);
    }

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
}
