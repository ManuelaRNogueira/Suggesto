package com.suggesto.backend.controller;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.Recompensa;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.MembroEquipeRepository;
import com.suggesto.backend.repository.RecompensaRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.service.CloudinaryService;
import com.suggesto.backend.util.UploadStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/recompensas")
@CrossOrigin(origins = "*")
public class RecompensaController {

    @Autowired
    private RecompensaRepository recompensaRepository;

    @Autowired
    private EstabelecimentoRepository estabelecimentoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private MembroEquipeRepository membroEquipeRepository;

    @Autowired
    private CloudinaryService cloudinaryService;

    // Todas as recompensas de todos os estabelecimentos, sem filtro — usado
    // em telas mais gerais (ex.: vitrine de recompensas do app).
    @GetMapping
    public ResponseEntity<List<Recompensa>> listarTodas() {
        return ResponseEntity.ok(recompensaRepository.findAll());
    }

    // Recompensas de um estabelecimento específico, da mais barata pra mais
    // cara em pontos — é o que aparece na tela de resgate daquele lugar.
    @GetMapping("/estabelecimento/{idEstabelecimento}")
    public ResponseEntity<List<Recompensa>> listarPorEstabelecimento(
            @PathVariable("idEstabelecimento") Long idEstabelecimento) {
        return ResponseEntity.ok(
                recompensaRepository.findByEstabelecimento_IdEstabelecimentoOrderByCustoPontosAsc(idEstabelecimento)
        );
    }

    // Estabelecimento cadastrando uma recompensa nova pro programa de pontos.
    // custoPontos e estabelecimentoId chegam como texto ou número dependendo
    // de como o front manda, por isso o parseInt/parseLong próprios lá embaixo
    // em vez de confiar no Jackson pra converter direto.
    @PostMapping
    public ResponseEntity<?> cadastrar(@RequestBody Map<String, Object> dados) {
        try {
            String nome = dados.get("nome") != null ? dados.get("nome").toString().trim() : "";
            String descricao = dados.get("descricao") != null ? dados.get("descricao").toString().trim() : "";
            Integer custoPontos = parseInt(dados.get("custoPontos"));
            Long idEstabelecimento = parseLong(dados.get("estabelecimentoId"));

            if (nome.isBlank() || custoPontos == null || custoPontos <= 0 || idEstabelecimento == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "nome, custoPontos e estabelecimentoId são obrigatórios."
                ));
            }

            Estabelecimento estabelecimento = estabelecimentoRepository.findById(idEstabelecimento)
                    .orElseThrow(() -> new IllegalArgumentException("Estabelecimento não encontrado."));

            Recompensa recompensa = new Recompensa();
            recompensa.setNome(nome);
            recompensa.setDescricao(descricao);
            recompensa.setCustoPontos(custoPontos);
            recompensa.setEstabelecimento(estabelecimento);
            recompensa.setDataCadastro(java.time.LocalDateTime.now());

            Recompensa salva = recompensaRepository.save(recompensa);
            return ResponseEntity.ok(salva);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "message", "Erro ao cadastrar recompensa: " + e.getMessage()
            ));
        }
    }

    // Foto própria da recompensa. Mesmo esquema do /api/estabelecimentos/{id}/foto:
    // o arquivo vai para a pasta uploads e o banco guarda só o nome dele.
    @PostMapping("/{id}/foto")
    public ResponseEntity<?> uploadFoto(
            @PathVariable("id") Long id,
            // required=false para o arquivo ausente virar um 400 nosso, e não um
            // 500 vindo da resolução de argumentos do Spring.
            @RequestParam(value = "foto", required = false) MultipartFile arquivo,
            @RequestParam(value = "idSolicitante", required = false) Long idSolicitante) {
        try {
            if (arquivo == null || arquivo.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false, "message", "Envie um arquivo de imagem."));
            }
            if (idSolicitante == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false, "message", "idSolicitante é obrigatório."));
            }

            Recompensa recompensa = recompensaRepository.findById(id).orElse(null);
            if (recompensa == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false, "message", "Recompensa não encontrada."));
            }

            Estabelecimento dono = recompensa.getEstabelecimento();
            if (dono == null) {
                throw new IllegalArgumentException("Recompensa sem estabelecimento vinculado.");
            }

            // Mesma regra de quem pode agir sobre o estabelecimento usada em
            // AvaliacaoService.responder: o gerente ou alguém da equipe dele.
            usuarioRepository.findById(idSolicitante)
                    .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

            boolean ehGerente = dono.getIdGerente() == idSolicitante;
            boolean ehDaEquipe = membroEquipeRepository
                    .existsByUsuario_IdAndEstabelecimento_IdEstabelecimento(idSolicitante, dono.getIdEstabelecimento());

            if (!ehGerente && !ehDaEquipe) {
                return ResponseEntity.status(403).body(Map.of(
                        "success", false,
                        "message", "Você não faz parte da equipe deste estabelecimento."));
            }

            String nomeLimpo = UploadStorage.normalizarNomeArquivo(arquivo.getOriginalFilename());
            String nomeArquivo = "recompensa_" + id + "_" + System.currentTimeMillis() + "_" + nomeLimpo;

            String fotoUrl = cloudinaryService.upload(arquivo, "recompensas", nomeArquivo);
            recompensa.setFotoPath(fotoUrl);
            return ResponseEntity.ok(recompensaRepository.save(recompensa));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false, "message", "Erro ao salvar a foto: " + e.getMessage()));
        }
    }

    // Remove a recompensa por completo do catálogo (não é um "desativar",
    // some mesmo do banco).
    @DeleteMapping("/{id}")
    public ResponseEntity<?> excluir(@PathVariable("id") Long id) {
        if (!recompensaRepository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", "Recompensa não encontrada."
            ));
        }
        recompensaRepository.deleteById(id);
        return ResponseEntity.ok(Map.of("success", true, "message", "Recompensa excluída."));
    }

    private Integer parseInt(Object valor) {
        if (valor == null) return null;
        if (valor instanceof Number n) return n.intValue();
        try {
            return Integer.parseInt(valor.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parseLong(Object valor) {
        if (valor == null) return null;
        if (valor instanceof Number n) return n.longValue();
        try {
            return Long.parseLong(valor.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
