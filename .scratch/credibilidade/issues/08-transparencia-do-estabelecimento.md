# 08: Transparência do estabelecimento

**What to build:** Cada estabelecimento ganha uma Transparência de 0 a 100, calculada na hora pelo histórico: quanto responde, quanto recusa e em quanto tempo reage (primeira resposta escrita ou data de decisão). A pontuação aparece com os números que a compõem na página pública (site e mobile) e no painel desktop.

**Blocked by:** 01

**Status:** resolved

- [x] Um serviço de reputação calcula a pontuação com a fórmula do spec (40 resposta, 40 não recusa, 20 agilidade), sem tabela nova
- [x] Menos de 5 avaliações resulta em "Sem dados suficientes", sem número
- [x] Rota pública devolve `{pontuacao | null, rotulo, componentes, total}`
- [x] A página do estabelecimento no site e as informações do local no mobile mostram a pontuação e os componentes
- [x] O painel desktop mostra a Transparência de cada estabelecimento
- [x] Testes com `@DataJpaTest` (H2) cobrem a fórmula com dados conhecidos, o limite de 5 e a agilidade nos extremos (48 h e 14 dias)
