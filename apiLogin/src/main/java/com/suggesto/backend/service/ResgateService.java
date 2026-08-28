package com.suggesto.backend.service;

import com.suggesto.backend.model.Recompensa;
import com.suggesto.backend.model.Resgate;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.RecompensaRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ResgateService {

    @Autowired
    private ResgateRepository resgateRepository;

    @Autowired
    private RecompensaRepository recompensaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository; // Necessário para buscar o usuário completo

    @Transactional
    public Map<String, Object> resgatar(Long usuarioId, Long recompensaId) {
        // 1. Busca o usuário no banco (se não achar, estoura erro)
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado com o ID: " + usuarioId));

        // 2. Busca a recompensa no banco (se não achar, estoura erro)
        Recompensa recompensa = recompensaRepository.findById(recompensaId)
                .orElseThrow(() -> new IllegalArgumentException("Recompensa não encontrada com o ID: " + recompensaId));

        // Cada cliente só resgata uma mesma recompensa uma vez — depois disso ela
        // some da vitrine dele (ver lojaPontos.dart / lojaPontosCli.js).
        if (resgateRepository.existsByUsuario_IdAndRecompensa_Id(usuarioId, recompensaId)) {
            throw new IllegalArgumentException("Você já resgatou esta recompensa.");
        }

        int custo = recompensa.getCustoPontos() != null ? recompensa.getCustoPontos() : 0;
        if (usuario.getPontos() < custo) {
            throw new IllegalArgumentException("Pontos insuficientes para este resgate.");
        }

        // 3. Debita os pontos do usuário antes de confirmar o resgate
        int linhasAfetadas = usuarioRepository.debitarPontos(usuarioId, custo);
        if (linhasAfetadas == 0) {
            throw new IllegalArgumentException("Pontos insuficientes para este resgate.");
        }

        // 4. Monta o objeto de Resgate preenchendo todos os campos obrigatórios
        Resgate resgate = new Resgate();
        resgate.setUsuario(usuario);
        resgate.setRecompensa(recompensa);
        resgate.setDataResgate(LocalDateTime.now()); // Salva o exato momento do resgate

        // Gera um código de cupom aleatório e limpo (ex: "RESG8A2F4B9")
        // Usamos UUID e pegamos os 8 primeiros caracteres para caber com folga no limite de 32 da tabela
        String cupomAleatorio = "RESG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        resgate.setCodigoCupom(cupomAleatorio);

        // 5. Salva no banco de dados
        Resgate salvo = resgateRepository.save(resgate);

        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("id", salvo.getId());
        resposta.put("codigoCupom", salvo.getCodigoCupom());
        resposta.put("dataResgate", salvo.getDataResgate());
        resposta.put("novoSaldo", usuario.getPontos() - custo);
        return resposta;
    }

    public List<Map<String, Object>> listarPorUsuario(Long usuarioId) {
        return resgateRepository.findByUsuario_IdOrderByDataResgateDesc(usuarioId).stream()
                .map(this::resumirResgate)
                .collect(Collectors.toList());
    }

    private Map<String, Object> resumirResgate(Resgate r) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", r.getId());
        item.put("idRecompensa", r.getRecompensa() != null ? r.getRecompensa().getId() : null);
        item.put("nomeRecompensa", r.getRecompensa() != null ? r.getRecompensa().getNome() : null);
        item.put("custoPontos", r.getRecompensa() != null ? r.getRecompensa().getCustoPontos() : null);
        item.put("estabelecimento",
                r.getRecompensa() != null && r.getRecompensa().getEstabelecimento() != null
                        ? r.getRecompensa().getEstabelecimento().getNome()
                        : null);
        item.put("dataResgate", r.getDataResgate());
        item.put("codigoCupom", r.getCodigoCupom());
        return item;
    }
}