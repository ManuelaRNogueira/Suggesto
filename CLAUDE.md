# Workflow

- Depois de concluir cada alteração pedida (código funcionando, sem erros de compilação), faça `git commit` e `git push` para o `origin/main` automaticamente, sem precisar perguntar antes.
- Mensagens de commit devem ser curtas e simples, no estilo humano do histórico do projeto (ex: "validação de telefone", "estilo minhas sugestoes"), não um changelog técnico em bullet points.
- Nunca adicione "Co-Authored-By: Claude" (ou qualquer menção à IA) nas mensagens de commit. Os commits devem aparecer só com a autoria da Manuela.
- Se a alteração for arriscada, destrutiva ou o escopo não estiver claro, avise antes de commitar/enviar em vez de seguir automaticamente.

# Contexto do projeto

## Duas máquinas
- O Diogo alterna entre o PC da escola e o de casa, e a Manuela trabalha em outra máquina. Quando algo funciona numa máquina e não na outra, confira primeiro se a `main` local está atrás do `origin/main` (`git pull`) e se as variáveis de ambiente existem, antes de investigar o código.
- Variáveis que cada máquina precisa (Windows, via `setx`, depois reabrir o VS Code/terminal): `DB_PASSWORD` (sem ela a API não conecta no banco), `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` (sem elas o upload de foto cai em disco local e a foto quebra). Os valores não ficam no repositório: peça ao Diogo.

## Hospedagem (Render)
- API: https://suggesto-api.onrender.com (health check em `/api/ping`). Site: https://suggestosite.onrender.com (sem hífen, diferente do nome no `render.yaml`).
- O deploy é automático: todo push na `main` vai ao ar, então cada commit é publicado.
- A API hiberna depois de 15 min sem uso e leva ~1 min para voltar. Logo depois de um deploy, 404 intermitente é propagação do Render: repita o teste antes de investigar.

## Decisões já tomadas
- A API não tem autenticação de verdade (o `SecurityAutoConfiguration` está desligado, CORS `*`, a identidade vem do cliente via `idUsuario`/`idAdmin`/`idSolicitante`). Foi uma escolha consciente por ser projeto escolar de demonstração; não reabra essa discussão. As senhas de usuário usam BCrypt.

## Pendências fora dos tickets
- Apagar os usuários de teste criados na API de produção (`Email LIKE 'teste.%'`).
- Trocar a senha do banco (a antiga ficou no histórico do git): trocar no serviço do banco, no Render e no DB_PASSWORD das máquinas.

## Agent skills

### Issue tracker

Issues vivem como arquivos markdown em `.scratch/<feature>/` neste repo. See `docs/agents/issue-tracker.md`.

### Triage labels

Os cinco papéis canônicos, com os nomes padrão. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: um `CONTEXT.md` na raiz + `docs/adr/`. See `docs/agents/domain.md`.
