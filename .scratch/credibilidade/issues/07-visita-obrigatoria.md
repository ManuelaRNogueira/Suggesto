# 07: Visita passa a ser obrigatória

**What to build:** Com o site e o mobile já mandando a visita, avaliar passa a exigir uma visita válida. Acaba o envio para o convidado genérico compartilhado: toda avaliação precisa de um usuário, e esse usuário precisa ter feito check-in.

**Blocked by:** 04, 05, 06

**Status:** resolved

- [x] Avaliação sem id de visita é recusada, com mensagem que orienta a fazer check-in
- [x] Visita expirada, já usada, ou de outro usuário ou local é recusada, com a mensagem de cada caso
- [x] Avaliação sem id de usuário é recusada (sai o fallback para o convidado compartilhado)
- [x] O site e o mobile mostram essas mensagens e levam o cliente ao check-in
- [x] O limite mensal do plano continua funcionando, depois da checagem da visita
- [x] Testes cobrem cada motivo de recusa e o caminho feliz

## Comments

- `AvaliacaoService.registrarNovaAvaliacao` recusa sem `idUsuario` e sem `idVisita`; a visita é conferida antes do `validarNovoFeedback`. Saiu o `UsuarioConvidadoSeeder` (o convidado compartilhado já criado no banco continua lá, com as avaliações antigas). Os motivos de visita inválida já eram testados no `VisitaServiceTest`; o `AvaliacaoServiceTest` cobre sem visita, sem usuário e a ordem visita → plano. Site e mobile bloqueiam o envio sem visita e, quando a API recusa por visita, tiram o selo e mostram o "Estou aqui" com o motivo. Conferido com `mvn test`, `dart analyze` e `node --check`; não rodei no navegador nem no aparelho.
