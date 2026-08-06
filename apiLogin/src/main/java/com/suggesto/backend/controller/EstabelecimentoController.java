package com.suggesto.backend.controller;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.util.UploadStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/estabelecimentos")
public class EstabelecimentoController {

    @Autowired
    private EstabelecimentoRepository repository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    private static final String ALFABETO_CODIGO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    private String gerarCodigoAcessoUnico() {
        String codigo;
        do {
            StringBuilder sufixo = new StringBuilder();
            for (int i = 0; i < 6; i++) {
                sufixo.append(ALFABETO_CODIGO.charAt(RANDOM.nextInt(ALFABETO_CODIGO.length())));
            }
            codigo = "SGT-" + sufixo;
        } while (repository.existsByCodigoAcesso(codigo));
        return codigo;
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> buscarPorId(@PathVariable Long id) {
        try {
            return repository.findById(id)
                    .map(estab -> {
                        aplicarMediasDeAvaliacao(List.of(estab));
                        return ResponseEntity.ok(estab);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao buscar detalhes: " + e.getMessage());
        }
    }

    @PostMapping(consumes = {"multipart/form-data"})
    public ResponseEntity<?> cadastrar(
            @RequestPart("estabelecimento") Estabelecimento novoEstabelecimento,
            @RequestPart(value = "foto", required = false) MultipartFile arquivo) {

        try {
            if (novoEstabelecimento.getAtivo() == null) {
                novoEstabelecimento.setAtivo(1);
            }

            novoEstabelecimento.setCodigoAcesso(gerarCodigoAcessoUnico());

            if (arquivo != null && !arquivo.isEmpty()) {
                // CORREÇÃO: Limpa o nome do arquivo ORIGINAL antes de gerar o caminho e salvar
                String nomeLimpo = UploadStorage.normalizarNomeArquivo(arquivo.getOriginalFilename());
                String nomeArquivo = System.currentTimeMillis() + "_" + nomeLimpo;

                Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
                Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);

                novoEstabelecimento.setFotoPath(nomeArquivo);
            }

            Estabelecimento salvo = repository.save(novoEstabelecimento);

            // Vincula o criador (dono/gerente) como membro do estabelecimento também,
            // para usar a mesma lógica de quem entra depois via código de acesso.
            usuarioRepository.findById(salvo.getIdGerente()).ifPresent(dono -> {
                dono.setEstabelecimento(salvo);
                usuarioRepository.save(dono);
            });

            return ResponseEntity.ok(salvo);

        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao salvar estabelecimento: " + e.getMessage());
        }
    }

    @PostMapping("/entrar")
    public ResponseEntity<?> entrarComCodigo(@RequestBody Map<String, Object> dados) {
        try {
            Object idUsuarioObj = dados.get("usuarioId");
            String codigo = (String) dados.get("codigo");

            if (idUsuarioObj == null || codigo == null || codigo.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Informe o usuário e o código do estabelecimento."
                ));
            }

            Long idUsuario = Long.valueOf(idUsuarioObj.toString());

            Optional<Usuario> usuarioOpt = usuarioRepository.findById(idUsuario);
            if (usuarioOpt.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Usuário não encontrado."
                ));
            }

            Usuario usuario = usuarioOpt.get();
            if (usuario.getTipoUsuario() != TipoUsuario.Administrador) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Você precisa ser um administrador para entrar em uma equipe."
                ));
            }

            if (repository.existsByIdGerenteAndAtivo(usuario.getId(), 1)) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Você já é o administrador principal de um estabelecimento e não pode entrar na equipe de outro."
                ));
            }

            Optional<Estabelecimento> estabOpt = repository.findByCodigoAcessoAndAtivo(codigo.trim().toUpperCase());
            if (estabOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of(
                        "success", false,
                        "message", "Código inválido. Confira com o responsável pelo estabelecimento."
                ));
            }

            Estabelecimento estabelecimento = estabOpt.get();
            usuario.setEstabelecimento(estabelecimento);
            usuarioRepository.save(usuario);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Você entrou na equipe!",
                    "nomeEstabelecimento", estabelecimento.getNome(),
                    "idGerente", estabelecimento.getIdGerente()
            ));

        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Usuário inválido."
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "message", "Erro interno ao entrar na equipe: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/gerente/{id}")
    public ResponseEntity<?> buscarPorGerente(@PathVariable Long id) {
        try {
            List<Estabelecimento> lista = repository.buscarPorGerenteAtivos(id);
            return ResponseEntity.ok(lista);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao buscar estabelecimento: " + e.getMessage());
        }
    }

    @PostMapping("/{id}/foto")
    public ResponseEntity<?> uploadFoto(@PathVariable Long id, @RequestParam("foto") MultipartFile arquivo) {
        try {
            Estabelecimento estab = repository.findById(id).orElseThrow(() -> new RuntimeException("Não encontrado"));

            // CORREÇÃO: Limpa o nome do arquivo ORIGINAL aqui também
            String nomeLimpo = UploadStorage.normalizarNomeArquivo(arquivo.getOriginalFilename());
            String nomeArquivo = "estabelecimento_" + id + "_" + nomeLimpo;
            
            Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
            Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);

            estab.setFotoPath(nomeArquivo);
            repository.save(estab);

            return ResponseEntity.ok("Foto salva com sucesso!" + nomeArquivo);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao salvar estabelecimento: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> inativarEstabelecimento(@PathVariable Long id) {
        return repository.findById(id).map(estab -> {
            estab.setAtivo(0);
            repository.save(estab);
            return ResponseEntity.ok().build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<Estabelecimento>> listarTodos() {
        try {
            List<Estabelecimento> lista = repository.buscarTodosAtivos();
            aplicarMediasDeAvaliacao(lista);
            return ResponseEntity.ok(lista);
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }

    @GetMapping("/usuario/{idGerente}")
    public ResponseEntity<List<Estabelecimento>> listarPorAdmin(@PathVariable Long idGerente) {
        return ResponseEntity.ok(repository.buscarPorGerenteAtivos(idGerente));
    }

    // Preenche a média/contagem de avaliações (calculadas, não persistidas) de cada estabelecimento.
    private void aplicarMediasDeAvaliacao(List<Estabelecimento> estabelecimentos) {
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