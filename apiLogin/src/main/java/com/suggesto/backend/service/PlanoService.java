package com.suggesto.backend.service;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Plano;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

// Traduz o que está escrito em planos.html em limites aplicados de verdade.
// Quem não tem plano definido não fica travado — é tratado como ilimitado,
// para não quebrar contas criadas antes do fluxo de planos existir.
@Service
public class PlanoService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    // Limites efetivos de um usuário administrador. Membro de equipe herda os
    // limites do dono do estabelecimento, não os da própria conta.
    public Plano planoEfetivo(Long idUsuario) {
        if (idUsuario == null) {
            return null;
        }
        Usuario usuario = usuarioRepository.findById(idUsuario).orElse(null);
        if (usuario == null) {
            return null;
        }

        Long idDono = usuario.getEstabelecimento() != null
                ? usuario.getEstabelecimento().getIdGerente()
                : usuario.getId();

        if (!idDono.equals(usuario.getId())) {
            Usuario dono = usuarioRepository.findById(idDono).orElse(null);
            if (dono != null) {
                return dono.getPlano();
            }
        }
        return usuario.getPlano();
    }

    public Long idDonoDoEstabelecimento(Estabelecimento estab) {
        return estab == null ? null : estab.getIdGerente();
    }

    // ── Checagens usadas pelos endpoints ─────────────────────────────────────

    public void validarNovoEstabelecimento(Long idGerente) {
        Plano plano = planoEfetivo(idGerente);
        Integer limite = plano == null ? null : plano.getLimiteEstabelecimentos();
        if (limite == null) return;

        long atuais = estabelecimentoRepository.buscarPorGerenteAtivos(idGerente).size();
        if (atuais >= limite) {
            throw new IllegalStateException(
                    "O plano " + plano.getNome() + " permite " + limite
                            + (limite == 1 ? " estabelecimento." : " estabelecimentos.")
                            + " Faça upgrade para cadastrar mais.");
        }
    }

    public void validarNovoFeedback(Estabelecimento estab) {
        Plano plano = planoEfetivo(idDonoDoEstabelecimento(estab));
        Integer limite = plano == null ? null : plano.getLimiteFeedbacksMes();
        if (limite == null) return;

        LocalDateTime inicioDoMes = LocalDateTime.now()
                .withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0).withNano(0);

        long noMes = avaliacaoRepository
                .findByEstabelecimentoId(estab.getIdEstabelecimento()).stream()
                .filter(a -> a.getDataAvaliacao() != null && !a.getDataAvaliacao().isBefore(inicioDoMes))
                .count();

        if (noMes >= limite) {
            throw new IllegalStateException(
                    "Este estabelecimento atingiu o limite de " + limite
                            + " feedbacks deste mês no plano " + plano.getNome() + ".");
        }
    }

    public void validarNovoAdmin(Long idGerente) {
        Plano plano = planoEfetivo(idGerente);
        Integer limite = plano == null ? null : plano.getLimiteAdmins();
        if (limite == null) return;

        long atuais = usuarioRepository.countByEstabelecimento_IdGerente(idGerente);
        if (atuais >= limite) {
            throw new IllegalStateException(
                    "O plano " + plano.getNome() + " permite "
                            + (limite == 1 ? "apenas o administrador principal." : limite + " administradores na equipe.")
                            + " Faça upgrade para adicionar mais.");
        }
    }

    // Resumo que o front usa para esconder o que o plano não inclui.
    public Map<String, Object> resumoDoPlano(Long idUsuario) {
        Plano plano = planoEfetivo(idUsuario);

        Map<String, Object> resumo = new LinkedHashMap<>();
        resumo.put("nome", plano == null ? null : plano.getNome());
        resumo.put("limiteEstabelecimentos", plano == null ? null : plano.getLimiteEstabelecimentos());
        resumo.put("limiteFeedbacksMes", plano == null ? null : plano.getLimiteFeedbacksMes());
        resumo.put("limiteAdmins", plano == null ? null : plano.getLimiteAdmins());
        resumo.put("permiteRelatorios", plano == null || plano.getPermiteRelatorios());
        resumo.put("permiteExportacao", plano == null || plano.getPermiteExportacao());
        resumo.put("permiteRecompensas", plano == null || plano.getPermiteRecompensas());
        return resumo;
    }
}
