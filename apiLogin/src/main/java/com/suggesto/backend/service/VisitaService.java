package com.suggesto.backend.service;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.model.Visita;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.repository.VisitaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;

// Check-in (a prova de que o cliente esteve no local) e a conferência dessa
// prova na hora de avaliar. Uma visita vale por JANELA e libera uma avaliação.
@Service
public class VisitaService {

    public static final Duration JANELA = Duration.ofHours(24);

    @Autowired
    private VisitaRepository visitaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    // Check-in pelo QR da mesa: o token lido tem que ser o atual do
    // estabelecimento (o dono pode trocar, e aí os QRs antigos param de valer).
    @Transactional
    public Visita checkinPorToken(Long idUsuario, Long idEstabelecimento, String token) {
        Usuario usuario = buscarUsuario(idUsuario);
        Estabelecimento estab = buscarEstabelecimento(idEstabelecimento);

        if (token == null || estab.getTokenCheckin() == null || !estab.getTokenCheckin().equals(token.trim())) {
            throw new IllegalArgumentException(
                    "Este QR não confirma visita (pode ser um QR antigo). Peça o QR atualizado no local.");
        }

        return visitaAbertaOuNova(usuario, estab, Visita.QR);
    }

    // Check-in sem QR: não confere a distância até o local, só registra a visita.
    // É o método mais fraco, por isso o método LOCALIZACAO fica gravado.
    @Transactional
    public Visita checkinPorLocalizacao(Long idUsuario, Long idEstabelecimento, Double lat, Double lng) {
        Usuario usuario = buscarUsuario(idUsuario);
        Estabelecimento estab = buscarEstabelecimento(idEstabelecimento);
        return visitaAbertaOuNova(usuario, estab, Visita.LOCALIZACAO);
    }

    // Confere a visita que veio junto da avaliação. As mensagens dizem o que
    // aconteceu, porque o cliente precisa saber se é pra fazer check-in de novo.
    public Visita validarParaAvaliacao(Long idVisita, Long idUsuario, Long idEstabelecimento) {
        Visita visita = visitaRepository.findById(idVisita)
                .orElseThrow(() -> new IllegalArgumentException("Visita não encontrada. Faça o check-in de novo."));

        boolean mesmoUsuario = visita.getUsuario() != null && visita.getUsuario().getId().equals(idUsuario);
        boolean mesmoLocal = visita.getEstabelecimento() != null
                && visita.getEstabelecimento().getIdEstabelecimento() == idEstabelecimento;
        if (!mesmoUsuario || !mesmoLocal) {
            throw new IllegalArgumentException("Esta visita não é sua ou é de outro estabelecimento.");
        }
        if (expirou(visita)) {
            throw new IllegalArgumentException("Sua visita expirou (vale 24 horas). Faça o check-in de novo no local.");
        }
        if (avaliacaoRepository.existsByVisita_Id(visita.getId())) {
            throw new IllegalArgumentException("Esta visita já foi usada numa avaliação. Faça o check-in na próxima visita.");
        }
        return visita;
    }

    public LocalDateTime expiraEm(Visita visita) {
        return visita.getDataCheckin().plus(JANELA);
    }

    private boolean expirou(Visita visita) {
        return !LocalDateTime.now().isBefore(expiraEm(visita));
    }

    // Um check-in por usuário e local a cada JANELA. Quem repete com a visita
    // ainda aberta (não usada) recebe a mesma; quem já usou a visita da janela
    // espera ela passar — senão ler o mesmo QR de novo (ou a foto dele) viraria
    // avaliações ilimitadas.
    private Visita visitaAbertaOuNova(Usuario usuario, Estabelecimento estab, String metodo) {
        LocalDateTime inicioDaJanela = LocalDateTime.now().minus(JANELA);
        for (Visita recente : visitaRepository.findByUsuario_IdAndEstabelecimento_IdEstabelecimentoAndDataCheckinAfter(
                usuario.getId(), estab.getIdEstabelecimento(), inicioDaJanela)) {
            if (!avaliacaoRepository.existsByVisita_Id(recente.getId())) {
                return recente;
            }
            long horas = (long) Math.ceil(Duration.between(LocalDateTime.now(), expiraEm(recente)).toMinutes() / 60.0);
            throw new IllegalArgumentException("Você já avaliou este local nas últimas 24 horas. "
                    + "Dá pra avaliar de novo em " + (horas <= 1 ? "1 hora" : horas + " horas") + ".");
        }

        Visita nova = new Visita();
        nova.setUsuario(usuario);
        nova.setEstabelecimento(estab);
        nova.setMetodo(metodo);
        nova.setDataCheckin(LocalDateTime.now());
        return visitaRepository.save(nova);
    }

    private Usuario buscarUsuario(Long idUsuario) {
        if (idUsuario == null) {
            throw new IllegalArgumentException("Entre na sua conta (ou como convidado) antes do check-in.");
        }
        return usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));
    }

    private Estabelecimento buscarEstabelecimento(Long idEstabelecimento) {
        return estabelecimentoRepository.findById(idEstabelecimento)
                .orElseThrow(() -> new IllegalArgumentException("Estabelecimento não encontrado."));
    }
}
