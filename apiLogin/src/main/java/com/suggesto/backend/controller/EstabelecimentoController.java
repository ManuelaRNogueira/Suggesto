package com.suggesto.backend.controller;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.util.UploadStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/estabelecimentos")
public class EstabelecimentoController {

    @Autowired
    private EstabelecimentoRepository repository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

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

            if (arquivo != null && !arquivo.isEmpty()) {
                // CORREÇÃO: Limpa o nome do arquivo ORIGINAL antes de gerar o caminho e salvar
                String nomeLimpo = UploadStorage.normalizarNomeArquivo(arquivo.getOriginalFilename());
                String nomeArquivo = System.currentTimeMillis() + "_" + nomeLimpo;
                
                Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
                Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);
                
                novoEstabelecimento.setFotoPath(nomeArquivo);
            }

            Estabelecimento salvo = repository.save(novoEstabelecimento);
            return ResponseEntity.ok(salvo);

        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao salvar estabelecimento: " + e.getMessage());
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