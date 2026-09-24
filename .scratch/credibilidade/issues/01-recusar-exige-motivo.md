# 01: Recusar exige motivo (API + desktop + site do cliente)

**What to build:** No painel desktop, recusar uma sugestão passa a pedir um motivo escrito, e o servidor só aceita as mudanças de status previstas no spec. O cliente lê o motivo no site, tanto em "Minhas sugestões" quanto na página pública do estabelecimento, onde a sugestão recusada continua visível e contando na média. Toda mudança de status grava uma data de decisão, que depois vai medir a agilidade da Transparência.

Spec: `../spec.md` (seção "Recusa com motivo").

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Recusar sem motivo, ou com motivo de menos de 10 caracteres (depois de tirar os espaços), é recusado pela API com mensagem clara, e a sugestão não muda
- [x] Recusar com motivo válido grava o motivo e a data de decisão
- [x] O servidor só aceita: pendente → implementado, pendente → recusado e recusado → pendente (que apaga o motivo). As outras transições são recusadas, e implementado é final
- [x] Qualquer mudança de status aceita grava a data de decisão
- [x] A checagem de equipe (`idAdmin`) continua valendo
- [x] No desktop, tanto na lista de sugestões quanto nos detalhes do estabelecimento, recusar pede o motivo antes de enviar e mostra o erro da API se houver
- [x] No site, "Minhas sugestões" e a página do estabelecimento mostram o motivo nas sugestões recusadas
- [x] Sugestões recusadas continuam aparecendo na página pública e contando na média
- [x] Testes no `AvaliacaoServiceTest` cobrem motivo ausente, motivo curto, motivo válido, cada transição permitida e proibida, e a data de decisão

## Comments

- Feito no commit `5e589d1`. Recusa inválida dá 400, transição proibida dá 409 e admin de fora da equipe dá 403. O resumo de `/admin/sugestoes` agora leva `motivoRecusa` e `dataDecisao`. Até o ticket 02 ficar pronto, recusar pelo admin do site e pelo admin do mobile retorna erro 400 pedindo o motivo.
