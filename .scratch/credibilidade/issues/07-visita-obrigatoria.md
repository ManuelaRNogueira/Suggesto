# 07: Visita passa a ser obrigatória

**What to build:** Com o site e o mobile já mandando a visita, avaliar passa a exigir uma visita válida. Acaba o envio para o convidado genérico compartilhado: toda avaliação precisa de um usuário, e esse usuário precisa ter feito check-in.

**Blocked by:** 04, 05, 06

**Status:** ready-for-agent

- [ ] Avaliação sem id de visita é recusada, com mensagem que orienta a fazer check-in
- [ ] Visita expirada, já usada, ou de outro usuário ou local é recusada, com a mensagem de cada caso
- [ ] Avaliação sem id de usuário é recusada (sai o fallback para o convidado compartilhado)
- [ ] O site e o mobile mostram essas mensagens e levam o cliente ao check-in
- [ ] O limite mensal do plano continua funcionando, depois da checagem da visita
- [ ] Testes cobrem cada motivo de recusa e o caminho feliz
