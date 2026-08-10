package com.suggesto.backend.controller;

import com.suggesto.backend.dto.AvaliacaoRequestDTO;
import com.suggesto.backend.model.Avaliacao;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.service.AvaliacaoService;
import com.suggesto.backend.util.NivelUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/avaliacoes")
@CrossOrigin(origins = "*")
public class AvaliacaoController {

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private AvaliacaoService avaliacaoService;

    @GetMapping("/estabelecimento/{id}")
    public List<Avaliacao> listarPorEstabelecimento(@PathVariable Long id) {
        return avaliacaoRepository.findByEstabelecimentoId(id);
    }

    @PostMapping
    public ResponseEntity<?> receberAvaliacao(@RequestBody AvaliacaoRequestDTO dto) {
        try {
            avaliacaoService.registrarNovaAvaliacao(dto);

            Map<String, String> sucesso = new HashMap<>();
            sucesso.put("mensagem", "Feedback registrado com sucesso!");
            return ResponseEntity.ok(sucesso);

        } catch (Exception e) {
            e.printStackTrace();

            Map<String, String> erro = new HashMap<>();
            erro.put("erro", e.getMessage());
            return ResponseEntity.badRequest().body(erro);
        }
    }

    // Feed de destaque da home do cliente: posts recentes de quem já subiu de
    // nível (Ouro/Platina). É o benefício visível de "destaque de posts".
    @GetMapping("/destaques")
    public ResponseEntity<List<Avaliacao>> destaques() {
        try {
            List<Avaliacao> destaques = avaliacaoRepository.findAllByOrderByDataAvaliacaoDesc().stream()
                    .filter(a -> a.getUsuario() != null
                            && NivelUtil.prioridade(a.getUsuario().getPontos()) >= 3)
                    .limit(6)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(destaques);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<List<Avaliacao>> listarPorUsuario(@PathVariable Long usuarioId) {
        try {
            List<Avaliacao> minhasAvaliacoes = avaliacaoRepository.buscarPorUsuario(usuarioId);
            return ResponseEntity.ok(minhasAvaliacoes);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PatchMapping("/{id}/resposta")
    public ResponseEntity<?> responder(
            @PathVariable("id") Long id,
            @RequestBody Map<String, Object> body) {
        try {
            Object idAdminBruto = body.get("idAdmin");
            if (idAdminBruto == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Campo idAdmin é obrigatório."
                ));
            }
            Long idAdmin = Long.valueOf(idAdminBruto.toString());
            String resposta = body.get("resposta") == null ? null : body.get("resposta").toString();

            Avaliacao atualizada = avaliacaoService.responder(id, idAdmin, resposta);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Resposta enviada.",
                    "avaliacao", atualizada
            ));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("success", false, "message", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> atualizarStatus(
            @PathVariable("id") Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Campo status é obrigatório."
                ));
            }
            Avaliacao atualizada = avaliacaoService.atualizarStatus(id, status);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Status atualizado.",
                    "avaliacao", atualizada
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }
}