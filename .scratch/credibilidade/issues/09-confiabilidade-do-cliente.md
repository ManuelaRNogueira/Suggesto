# 09: Confiabilidade do cliente

**What to build:** Cada cliente ganha uma Confiabilidade de 0 a 100: das avaliações feitas com visita (ou seja, depois do lançamento), qual a fração aceita. As avaliações antigas não contam, nem a favor nem contra. A pontuação aparece no perfil do cliente (site e mobile) e ao lado do autor nas listas de sugestões do desktop e do admin do site, sem expor dado pessoal.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] O serviço de reputação calcula round(100 × aceitas / (aceitas + recusadas)) só sobre avaliações com visita; pendentes não contam
- [ ] Menos de 3 avaliações decididas na conta resulta em "Novo", sem número
- [ ] Rota pública devolve `{pontuacao | null, rotulo, componentes, total}`
- [ ] O perfil do cliente no site e no mobile mostra a pontuação e quantas avaliações entraram na conta
- [ ] As listas de sugestões do desktop e do admin do site mostram a Confiabilidade do autor, calculada em lote (e não uma consulta por sugestão)
- [ ] Nenhuma resposta nova expõe e-mail, telefone ou CPF
- [ ] Testes com `@DataJpaTest` (H2) cobrem a fórmula, o limite de "Novo", pendentes fora da conta, e avaliações sem visita não mudando a pontuação
