package com.suggesto.backend.controller;

import com.suggesto.backend.model.Estabelecimento;
import com.suggesto.backend.model.SolicitacaoEquipe;
import com.suggesto.backend.model.TipoUsuario;
import com.suggesto.backend.model.Usuario;
import com.suggesto.backend.repository.AvaliacaoRepository;
import com.suggesto.backend.repository.EstabelecimentoRepository;
import com.suggesto.backend.repository.SolicitacaoEquipeRepository;
import com.suggesto.backend.repository.UsuarioRepository;
import com.suggesto.backend.util.DocumentoValidator;
import com.suggesto.backend.util.TextoUtil;
import com.suggesto.backend.util.UploadStorage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.SecureRandom;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/estabelecimentos")
public class EstabelecimentoController {

    @Autowired
    private EstabelecimentoRepository repository;

    @Autowired
    private AvaliacaoRepository avaliacaoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private SolicitacaoEquipeRepository solicitacaoRepository;

    @Autowired
    private com.suggesto.backend.service.PlanoService planoService;

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
            if (!DocumentoValidator.isCnpjValido(novoEstabelecimento.getCnpj())) {
                return ResponseEntity.badRequest().body("CNPJ inválido.");
            }
            if (repository.existsByCnpj(novoEstabelecimento.getCnpj())) {
                return ResponseEntity.badRequest().body("Este CNPJ já está cadastrado.");
            }

            planoService.validarNovoEstabelecimento(novoEstabelecimento.getIdGerente());

            if (novoEstabelecimento.getAtivo() == null) {
                novoEstabelecimento.setAtivo(1);
            }

            novoEstabelecimento.setCidade(TextoUtil.capitalizarNomeProprio(novoEstabelecimento.getCidade()));
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
            // Uma conta já existente vinculada como responsável (fluxo "já tenho
            // conta") vira Administrador na hora, já que é ela que vai gerenciar o painel.
            usuarioRepository.findById(salvo.getIdGerente()).ifPresent(dono -> {
                dono.setEstabelecimento(salvo);
                if (dono.getTipoUsuario() != TipoUsuario.Administrador) {
                    dono.setTipoUsuario(TipoUsuario.Administrador);
                }
                usuarioRepository.save(dono);
            });

            return ResponseEntity.ok(salvo);

        } catch (IllegalStateException e) {
            // Limite do plano atingido — a mensagem já é escrita para o usuário.
            return ResponseEntity.status(403).body(e.getMessage());
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

            if (usuario.getEstabelecimento() != null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Você já faz parte de um estabelecimento."
                ));
            }

            if (solicitacaoRepository.findByUsuario_Id(usuario.getId()).isPresent()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Você já tem uma solicitação pendente. Aguarde o administrador responder."
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

            SolicitacaoEquipe solicitacao = new SolicitacaoEquipe();
            solicitacao.setUsuario(usuario);
            solicitacao.setEstabelecimento(estabelecimento);
            solicitacaoRepository.save(solicitacao);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "pendente", true,
                    "message", "Solicitação enviada! Aguarde a aprovação do administrador principal.",
                    "nomeEstabelecimento", estabelecimento.getNome()
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

    @GetMapping("/solicitacoes")
    public ResponseEntity<?> listarSolicitacoes(@RequestParam(value = "idGerente", required = false) Long idGerente) {
        if (idGerente == null) {
            return ResponseEntity.ok(List.of());
        }

        List<Map<String, Object>> lista = solicitacaoRepository
                .findByEstabelecimento_IdGerenteOrderByDataSolicitacaoAsc(idGerente)
                .stream()
                .map(s -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", s.getId());
                    item.put("nomeUsuario", s.getUsuario().getNome());
                    item.put("emailUsuario", s.getUsuario().getEmail());
                    item.put("estabelecimentoId", s.getEstabelecimento().getIdEstabelecimento());
                    item.put("nomeEstabelecimento", s.getEstabelecimento().getNome());
                    item.put("dataSolicitacao", s.getDataSolicitacao());
                    return item;
                })
                .collect(java.util.stream.Collectors.toList());

        return ResponseEntity.ok(lista);
    }

    @PostMapping("/solicitacoes/{id}/aceitar")
    public ResponseEntity<?> aceitarSolicitacao(@PathVariable Long id, @RequestBody Map<String, Object> dados) {
        return resolverSolicitacao(id, dados, true);
    }

    @PostMapping("/solicitacoes/{id}/recusar")
    public ResponseEntity<?> recusarSolicitacao(@PathVariable Long id, @RequestBody Map<String, Object> dados) {
        return resolverSolicitacao(id, dados, false);
    }

    private ResponseEntity<?> resolverSolicitacao(Long id, Map<String, Object> dados, boolean aceitar) {
        try {
            Object idGerenteObj = dados.get("idGerente");
            if (idGerenteObj == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Informe o administrador responsável."
                ));
            }
            Long idGerente = Long.valueOf(idGerenteObj.toString());

            Optional<SolicitacaoEquipe> solicitacaoOpt = solicitacaoRepository.findById(id);
            if (solicitacaoOpt.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of(
                        "success", false,
                        "message", "Solicitação não encontrada."
                ));
            }

            SolicitacaoEquipe solicitacao = solicitacaoOpt.get();
            if (solicitacao.getEstabelecimento().getIdGerente() != idGerente) {
                return ResponseEntity.status(403).body(Map.of(
                        "success", false,
                        "message", "Você não pode responder a essa solicitação."
                ));
            }

            if (aceitar) {
                planoService.validarNovoAdmin(idGerente);
                Usuario usuario = solicitacao.getUsuario();
                usuario.setEstabelecimento(solicitacao.getEstabelecimento());
                usuarioRepository.save(usuario);
            }

            solicitacaoRepository.delete(solicitacao);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", aceitar ? "Solicitação aceita." : "Solicitação recusada."
            ));

        } catch (IllegalStateException e) {
            // Limite de administradores do plano atingido.
            return ResponseEntity.status(403).body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Administrador inválido."
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "message", "Erro interno ao responder a solicitação: " + e.getMessage()
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
    public ResponseEntity<?> uploadFoto(
            @PathVariable Long id,
            @RequestParam("foto") MultipartFile arquivo,
            @RequestParam("idSolicitante") Long idSolicitante) {
        try {
            Estabelecimento estab = repository.findById(id).orElseThrow(() -> new RuntimeException("Não encontrado"));

            if (estab.getIdGerente() != idSolicitante) {
                return ResponseEntity.status(403).body("Apenas o administrador principal pode editar este estabelecimento.");
            }

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

    @PutMapping(value = "/{id}", consumes = {"multipart/form-data"})
    public ResponseEntity<?> atualizar(
            @PathVariable Long id,
            @RequestPart("estabelecimento") Estabelecimento dadosAtualizados,
            @RequestPart(value = "foto", required = false) MultipartFile arquivo,
            @RequestParam("idSolicitante") Long idSolicitante,
            @RequestParam("codigoConfirmacao") String codigoConfirmacao) {
        try {
            Estabelecimento estab = repository.findById(id).orElse(null);
            if (estab == null) {
                return ResponseEntity.notFound().build();
            }

            if (estab.getIdGerente() != idSolicitante) {
                return ResponseEntity.status(403).body("Apenas o administrador principal pode editar este estabelecimento.");
            }

            if (estab.getCodigoAcesso() == null
                    || !estab.getCodigoAcesso().equalsIgnoreCase(codigoConfirmacao == null ? "" : codigoConfirmacao.trim())) {
                return ResponseEntity.status(403).body("Código da equipe incorreto.");
            }

            if (!DocumentoValidator.isCnpjValido(dadosAtualizados.getCnpj())) {
                return ResponseEntity.badRequest().body("CNPJ inválido.");
            }
            if (repository.existsByCnpjAndIdEstabelecimentoNot(dadosAtualizados.getCnpj(), id)) {
                return ResponseEntity.badRequest().body("Este CNPJ já está cadastrado.");
            }

            estab.setNome(dadosAtualizados.getNome());
            estab.setCnpj(dadosAtualizados.getCnpj());
            estab.setCategoria(dadosAtualizados.getCategoria());
            estab.setTelefone(dadosAtualizados.getTelefone());
            estab.setCep(dadosAtualizados.getCep());
            estab.setEstado(dadosAtualizados.getEstado());
            estab.setCidade(TextoUtil.capitalizarNomeProprio(dadosAtualizados.getCidade()));
            estab.setBairro(dadosAtualizados.getBairro());
            estab.setRua(dadosAtualizados.getRua());
            estab.setNumero(dadosAtualizados.getNumero());
            estab.setComplemento(dadosAtualizados.getComplemento());
            estab.setHorarioFuncionamento(dadosAtualizados.getHorarioFuncionamento());
            estab.setSobre(dadosAtualizados.getSobre());

            if (arquivo != null && !arquivo.isEmpty()) {
                String nomeLimpo = UploadStorage.normalizarNomeArquivo(arquivo.getOriginalFilename());
                String nomeArquivo = "estabelecimento_" + id + "_" + System.currentTimeMillis() + "_" + nomeLimpo;

                Path caminho = UploadStorage.resolverArquivo(nomeArquivo);
                Files.copy(arquivo.getInputStream(), caminho, StandardCopyOption.REPLACE_EXISTING);

                estab.setFotoPath(nomeArquivo);
            }

            Estabelecimento salvo = repository.save(estab);
            return ResponseEntity.ok(salvo);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erro ao atualizar estabelecimento: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}/administradores/{idUsuario}")
    public ResponseEntity<?> removerAdministrador(
            @PathVariable Long id,
            @PathVariable Long idUsuario,
            @RequestParam("idSolicitante") Long idSolicitante,
            @RequestParam("codigoConfirmacao") String codigoConfirmacao) {
        try {
            Estabelecimento estab = repository.findById(id).orElse(null);
            if (estab == null) {
                return ResponseEntity.notFound().build();
            }

            if (estab.getIdGerente() != idSolicitante) {
                return ResponseEntity.status(403).body(Map.of(
                        "success", false,
                        "message", "Apenas o administrador principal pode gerenciar a equipe."
                ));
            }

            if (estab.getCodigoAcesso() == null
                    || !estab.getCodigoAcesso().equalsIgnoreCase(codigoConfirmacao == null ? "" : codigoConfirmacao.trim())) {
                return ResponseEntity.status(403).body(Map.of(
                        "success", false,
                        "message", "Código da equipe incorreto."
                ));
            }

            if (estab.getIdGerente() == idUsuario) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "O administrador principal não pode remover a si mesmo."
                ));
            }

            Usuario usuario = usuarioRepository.findById(idUsuario).orElse(null);
            if (usuario == null || usuario.getEstabelecimento() == null
                    || usuario.getEstabelecimento().getIdEstabelecimento() != id) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Esse administrador não faz parte da equipe deste estabelecimento."
                ));
            }

            usuario.setEstabelecimento(null);
            usuarioRepository.save(usuario);

            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "message", "Erro ao remover administrador: " + e.getMessage()
            ));
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

    // Recomendação simples por proximidade: estabelecimentos ativos na mesma cidade
    // do cliente, dos mais bem avaliados para os menos. Sem geolocalização.
    @GetMapping("/recomendados")
    public ResponseEntity<List<Estabelecimento>> recomendados(@RequestParam("idUsuario") Long idUsuario) {
        try {
            String cidade = usuarioRepository.findById(idUsuario)
                    .map(Usuario::getCidade)
                    .orElse(null);

            if (cidade == null || cidade.isBlank()) {
                return ResponseEntity.ok(List.of());
            }

            List<Estabelecimento> daCidade = repository.buscarTodosAtivos().stream()
                    .filter(e -> TextoUtil.mesmoTexto(cidade, e.getCidade()))
                    .collect(Collectors.toList());

            aplicarMediasDeAvaliacao(daCidade);
            daCidade.sort(Comparator.comparingDouble(
                    (Estabelecimento e) -> e.getMediaAvaliacoes() == null ? 0d : e.getMediaAvaliacoes()
            ).reversed());

            return ResponseEntity.ok(daCidade);
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
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