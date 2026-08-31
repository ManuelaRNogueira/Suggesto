package com.suggesto.backend.service;

import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.LocalSalvoRepository;
import com.suggesto.backend.repository.ResgateRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.util.NivelUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Conquistas são sempre derivadas de contadores que o sistema já rastreia —
// não existe tabela de conquista, então nada precisa ser sincronizado nem pode
// ficar desatualizado em relação ao que o cliente realmente fez.
@Service
public class ConquistaService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private LocalSalvoRepository localSalvoRepository;

    @Autowired
    private ResgateRepository resgateRepository;

    // Aqui a gente não guarda "conquista desbloqueada" em lugar nenhum — toda
    // vez que a tela pede, comparamos os números atuais do usuário (quantas
    // sugestões enviou, quantas foram aprovadas, quantos locais salvou,
    // quantos resgates fez, quantos pontos tem) com a meta de cada selo. Se
    // já bateu ou passou da meta, o selo aparece desbloqueado.
    public List<Map<String, Object>> listarPorUsuario(Long idUsuario) {
        Usuario usuario = usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

        long enviadas = avaliacaoRepository.countByUsuario_Id(idUsuario);
        long aprovadas = avaliacaoRepository.contarAprovadasPorUsuario(idUsuario);
        long salvos = localSalvoRepository.countByUsuarioId(idUsuario);
        long resgates = resgateRepository.countByUsuario_Id(idUsuario);
        int pontos = usuario.getPontos();

        List<Map<String, Object>> conquistas = new ArrayList<>();

        conquistas.add(montar("pioneiro", "Pioneiro", "fa-paper-plane",
                "Envie sua primeira sugestão", enviadas, 1));
        conquistas.add(montar("em-chamas", "Em chamas", "fa-fire",
                "Envie 10 sugestões", enviadas, 10));
        conquistas.add(montar("veterano", "Veterano", "fa-star",
                "Envie 50 sugestões", enviadas, 50));

        conquistas.add(montar("vencedor", "Vencedor", "fa-trophy",
                "Tenha uma sugestão aprovada", aprovadas, 1));
        conquistas.add(montar("influente", "Influente", "fa-bullhorn",
                "Tenha 10 sugestões aprovadas", aprovadas, 10));

        conquistas.add(montar("explorador", "Explorador", "fa-compass",
                "Salve 5 estabelecimentos", salvos, 5));
        conquistas.add(montar("colecionador", "Colecionador", "fa-bookmark",
                "Salve 15 estabelecimentos", salvos, 15));

        conquistas.add(montar("primeiro-resgate", "Primeiro resgate", "fa-gift",
                "Resgate sua primeira recompensa", resgates, 1));
        conquistas.add(montar("comprador", "Comprador", "fa-shopping-bag",
                "Resgate 5 recompensas", resgates, 5));

        conquistas.add(montar("bronze", "Bronze", "fa-medal",
                "Comece sua jornada no Suggesto", pontos, 0));
        conquistas.add(montar("prata", "Prata", "fa-medal",
                "Alcance " + NivelUtil.MIN_PRATA + " pontos", pontos, NivelUtil.MIN_PRATA));
        conquistas.add(montar("ouro", "Ouro", "fa-medal",
                "Alcance " + NivelUtil.MIN_OURO + " pontos", pontos, NivelUtil.MIN_OURO));
        conquistas.add(montar("platina", "Platina", "fa-gem",
                "Alcance " + NivelUtil.MIN_PLATINA + " pontos", pontos, NivelUtil.MIN_PLATINA));

        return conquistas;
    }

    // Monta o "card" de uma conquista: trava o progresso no teto da meta (não
    // deixa mostrar mais que 100%) e já calcula sozinho se ela foi desbloqueada.
    private Map<String, Object> montar(String id, String nome, String icone,
                                       String descricao, long progresso, long meta) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", id);
        item.put("nome", nome);
        item.put("icone", icone);
        item.put("descricao", descricao);
        item.put("progresso", Math.min(progresso, meta));
        item.put("meta", meta);
        item.put("desbloqueada", progresso >= meta);
        return item;
    }
}
