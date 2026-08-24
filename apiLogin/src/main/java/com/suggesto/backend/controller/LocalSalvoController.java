package com.suggesto.backend.controller;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.LocalSalvo;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.LocalSalvoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/locais-salvos")
public class LocalSalvoController {

    @Autowired
    private LocalSalvoRepository localSalvoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private com.suggesto.backend.service.AvaliacaoService avaliacaoService;

    @PostMapping
    public ResponseEntity<?> salvar(@RequestBody Map<String, Long> dados) {
        try {
            Long usuarioId = dados.get("usuarioId");
            Long estabelecimentoId = dados.get("estabelecimentoId");

            if (usuarioId == null || estabelecimentoId == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "usuarioId e estabelecimentoId são obrigatórios."
                ));
            }

            if (!usuarioRepository.existsById(usuarioId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "message", "Usuário não encontrado."
                ));
            }

            if (!estabelecimentoRepository.existsById(estabelecimentoId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "message", "Estabelecimento não encontrado."
                ));
            }

            if (localSalvoRepository.existsByUsuarioIdAndEstabelecimentoId(usuarioId, estabelecimentoId)) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "Local já estava salvo."
                ));
            }

            LocalSalvo localSalvo = new LocalSalvo();
            localSalvo.setUsuarioId(usuarioId);
            localSalvo.setEstabelecimentoId(estabelecimentoId);
            localSalvo.setDataSalvo(LocalDateTime.now());

            localSalvoRepository.save(localSalvo);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Local salvo com sucesso."
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", "Erro ao salvar local: " + e.getMessage()
            ));
        }
    }

    @DeleteMapping("/{usuarioId}/{estabelecimentoId}")
    @Transactional
    public ResponseEntity<?> deletar(
            @PathVariable("usuarioId") Long usuarioId,
            @PathVariable("estabelecimentoId") Long estabelecimentoId) {
        if (usuarioId == null || usuarioId <= 0 || estabelecimentoId == null || estabelecimentoId <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", "usuarioId e estabelecimentoId devem ser números válidos."
            ));
        }

        Optional<LocalSalvo> localSalvo = localSalvoRepository
                .findByUsuarioIdAndEstabelecimentoId(usuarioId, estabelecimentoId);

        if (localSalvo.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", "Local salvo não encontrado."
            ));
        }

        localSalvoRepository.delete(localSalvo.get());

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Local removido dos salvos."
        ));
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<?> listarPorUsuario(@PathVariable Long usuarioId) {
        try {
            if (!usuarioRepository.existsById(usuarioId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "message", "Usuário não encontrado."
                ));
            }

            List<LocalSalvo> salvos = localSalvoRepository.findByUsuarioId(usuarioId);
            List<Estabelecimento> estabelecimentos = new ArrayList<>();

            for (LocalSalvo salvo : salvos) {
                estabelecimentoRepository.findById(salvo.getEstabelecimentoId())
                        .ifPresent(estabelecimentos::add);
            }

            // Sem isso, mediaAvaliacoes/totalAvaliacoes vêm sempre null aqui —
            // são campos @Transient, só preenchidos quando alguém calcula (ver
            // AvaliacaoService.aplicarMediasDeAvaliacao). O card de Locais
            // Salvos no front depende desse valor pra mostrar a nota real.
            avaliacaoService.aplicarMediasDeAvaliacao(estabelecimentos);

            return ResponseEntity.ok(estabelecimentos);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "success", false,
                    "message", "Erro ao listar locais salvos: " + e.getMessage()
            ));
        }
    }
}
