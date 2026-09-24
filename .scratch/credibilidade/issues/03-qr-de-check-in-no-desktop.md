# 03: QR de check-in do estabelecimento no desktop

**What to build:** Cada estabelecimento ganha um token de check-in, separado do `codigoAcesso` (que é a chave da equipe e nunca pode ir para uma mesa). O dono vê o QR de check-in no painel desktop, imprime e pode gerar um novo quando a foto do antigo vazar. O QR aponta para a página de avaliação do site com o id do estabelecimento e o token.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Estabelecimento novo nasce com token de check-in, e os que já existem recebem um por uma migração idempotente no boot
- [x] O token nunca sai no JSON por padrão (avaliações, recompensas, listas, detalhe) e só é revelado ao dono, no mesmo esquema de proteção do `codigoAcesso`
- [x] Rota que gera um novo token, só para o dono (403 para os outros); o token antigo deixa de valer na hora
- [x] O desktop mostra o QR com a URL da página de avaliação, levando o id e o token, e tem uma opção de imprimir
- [x] "Gerar novo QR" pede confirmação avisando que os QRs já impressos vão parar de confirmar visitas
- [x] O desktop avisa quando o estabelecimento não tem coordenadas salvas e, por isso, só o QR vai funcionar
- [x] Testes: token não serializado por padrão e revelado ao dono, migração idempotente, geração de novo token (só o dono)

## Comments

- Feito no commit `a46789c`. O token tem 16 caracteres [a-z0-9]. O QR aponta para `https://suggestosite.onrender.com/fazerSugestao.html?id=<id>&t=<token>` (dá pra trocar o endereço com VITE_SITE_URL). O método de revelar da entidade virou `revelarDadosDoDono()` e libera o código da equipe e o token juntos. `GET /estabelecimentos/{id}` aceita `idSolicitante`. O desktop ganhou a dependência `qrcode`. A migração já rodou no MySQL real. Até o ticket 04, a página do site ignora o parâmetro `t`.
