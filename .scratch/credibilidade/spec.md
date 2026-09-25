# Credibilidade e reputação

Status: ready-for-agent

> Revisado e quebrado em tickets em `issues/`.

## Problem Statement

Hoje o Suggesto não tem como distinguir uma avaliação de quem realmente consumiu no estabelecimento de uma avaliação feita do sofá, por alguém que nunca pisou lá. Qualquer cliente (ou convidado) avalia qualquer estabelecimento, quantas vezes quiser, de qualquer lugar. Isso deixa a nota média e o feed de sugestões vulneráveis a spam, concorrência desleal e avaliações inventadas.

Do outro lado, o estabelecimento consegue recusar uma sugestão com um clique, sem dizer por quê. Para o cliente, isso parece uma forma silenciosa de "abafar" críticas: a sugestão é recusada, ele não ganha pontos, e ninguém sabe o motivo.

Por fim, não existe nenhum sinal de confiança visível: o estabelecimento não sabe se o autor de uma sugestão costuma ser sério, e o cliente não sabe se o estabelecimento costuma levar feedback a sério. A banca pediu explicitamente para "pensar em mecanismo de reputação".

## Solution

Três mudanças que se reforçam:

1. **Visita confirmada antes de avaliar.** Para avaliar um estabelecimento, o cliente precisa antes registrar uma **visita** a ele: lendo o QR de check-in que fica no local ou confirmando pela localização do aparelho que está lá. A visita vale por um tempo limitado e libera **uma** avaliação. Cada avaliação nova sai marcada com a forma como a visita foi confirmada.

2. **Recusa com motivo.** Recusar uma sugestão passa a exigir um motivo escrito. O motivo aparece para o autor e na página pública do estabelecimento, junto da sugestão recusada, que continua visível e contando na média (como já é hoje). Estabelecimento não apaga avaliações.

3. **Reputação dos dois lados.** O cliente ganha uma **Confiabilidade** (0–100) calculada pelo histórico dele: das avaliações que ele fez com visita confirmada, quantas foram aceitas. As avaliações de antes desta funcionalidade não entram na conta, nem a favor nem contra. O estabelecimento ganha uma **Transparência** (0–100) calculada por quanto ele responde, quanto recusa e em quanto tempo responde. As duas aparecem junto com os números que as compõem, e nada é guardado em tabela: tudo é recalculado a partir do histórico, como as conquistas já são hoje.

## User Stories

### Visita e check-in

1. Como cliente no estabelecimento, quero ler o QR da mesa com a câmera normal do celular, para confirmar minha visita sem precisar instalar o app.
2. Como cliente com o app mobile, quero ler o QR do estabelecimento pelo leitor do próprio app, para que a visita seja confirmada e o formulário de sugestão já abra naquele local.
3. Como cliente sem QR por perto, quero confirmar minha visita pela localização do celular, para conseguir avaliar um lugar que não imprimiu o QR.
4. Como cliente, quero ser avisado claramente quando minha localização está longe demais do estabelecimento, para entender por que a avaliação não foi liberada.
5. Como cliente, quero ser avisado quando o navegador ou o celular negou a permissão de localização, para saber que preciso permitir ou usar o QR.
6. Como cliente, quero que minha visita continue valendo por um tempo depois que eu sair, para poder escrever a avaliação com calma em casa no mesmo dia.
7. Como cliente, quero ver que minha visita expirou quando tento avaliar tarde demais, para saber que preciso fazer check-in na próxima visita.
8. Como cliente, quero que uma visita libere uma avaliação, para a regra ser simples e previsível.
9. Como convidado que chegou pelo QR, quero que minha visita seja confirmada na chegada, para avaliar sem criar conta.
10. Como cliente, quero que QRs antigos já impressos (que só têm o id do estabelecimento) continuem abrindo a página de avaliação, para nada do que já foi impresso quebrar, mesmo que eles sozinhos não confirmem a visita.
11. Como cliente, quero que minha avaliação apareça com o selo "Visita confirmada", para que as outras pessoas e o estabelecimento saibam que ela é confiável.
12. Como cliente lendo avaliações, quero ver quais tiveram visita confirmada, para pesar isso na hora de escolher um lugar.
13. Como cliente lendo avaliações, quero que as avaliações antigas (de antes dessa funcionalidade) continuem visíveis sem o selo, para o histórico não ser apagado.
14. Como cliente que já avaliava antes dessa funcionalidade, quero que minhas avaliações antigas não contem na minha Confiabilidade, nem a favor nem contra, para que um histórico feito sob regras diferentes não me beneficie nem me prejudique.

### Check-in do lado do estabelecimento

15. Como gerente, quero ver e imprimir o QR de check-in do meu estabelecimento no painel, para colocar nas mesas e no balcão.
16. Como gerente, quero que o QR de check-in seja diferente do código de acesso da equipe, para que imprimi-lo na mesa nunca exponha a chave da minha equipe.
17. Como gerente, quero gerar um novo QR de check-in quando a foto do antigo vazar na internet, para ninguém "visitar" de casa usando a foto.
18. Como gerente, quero ser avisado, antes de gerar um novo QR de check-in, que os impressos vão parar de confirmar visitas, para não inutilizar meu material impresso sem querer.
19. Como gerente de um estabelecimento sem coordenadas salvas, quero ser avisado que o check-in por localização não vai funcionar até o endereço ser geocodificado, para saber que preciso contar com o QR.

### Recusa com motivo

20. Como gerente ou membro da equipe, quero ser obrigado a escrever um motivo ao recusar uma sugestão, para que as recusas sejam justificadas e não arbitrárias.
21. Como gerente, quero uma mensagem clara quando o motivo estiver vazio ou curto demais, para corrigir antes de enviar.
22. Como gerente, quero voltar uma sugestão recusada para pendente se recusei por engano, para poder corrigir erros.
23. Como cliente que teve a sugestão recusada, quero ler o motivo em "Minhas sugestões", para entender a decisão.
24. Como cliente lendo a página de um estabelecimento, quero ver as sugestões recusadas junto com o motivo, para julgar se o estabelecimento está sendo justo.
25. Como cliente, quero que as sugestões recusadas continuem contando na média do estabelecimento, para que recusar não sirva para limpar a nota.
26. Como cliente, quero ter certeza de que o estabelecimento não consegue apagar minha sugestão, para que um feedback ruim não possa sumir.

### Reputação do cliente

27. Como cliente, quero ver minha Confiabilidade no meu perfil, para saber como os estabelecimentos me enxergam.
28. Como cliente, quero ver do que minha pontuação é feita (taxa de aceitação e quantas avaliações entraram na conta), para entender como melhorar.
29. Como cliente novo, com pouco histórico, quero aparecer como "Novo" em vez de ter uma pontuação baixa, para não ser punido por ser novo.
30. Como gerente, quero ver a Confiabilidade do autor em cada sugestão no painel, para priorizar sugestões de pessoas confiáveis.
31. Como gerente, quero que a pontuação do autor nunca revele os dados pessoais dele, para manter a privacidade do cliente (coerente com a correção de privacidade recente).

### Reputação do estabelecimento

32. Como cliente, quero ver a Transparência de um estabelecimento na página pública dele, para saber se ele ouve os feedbacks.
33. Como cliente, quero ver os números por trás da pontuação (taxa de resposta, taxa de recusa, tempo médio de resposta), para a pontuação não ser uma caixa-preta.
34. Como cliente, quero que estabelecimentos com poucas sugestões mostrem "Sem dados suficientes", para que uma ou duas sugestões não gerem uma pontuação enganosa.
35. Como gerente, quero ver a Transparência do meu estabelecimento no painel, para saber como o comportamento da minha equipe é percebido.
36. Como gerente, quero entender que recusar muito e responder devagar baixa minha pontuação, para que o incentivo seja responder de forma justa e rápida.

### Banca / apresentação

37. Como avaliador da banca, quero acompanhar uma demonstração de ponta a ponta (ler o QR → avaliar com selo → recusar com motivo → as pontuações mudarem), para ver o mecanismo funcionando em poucos minutos.

## Implementation Decisions

### Visita (check-in)

- **Nova entidade `Visita`**: usuário, estabelecimento, momento do check-in, método (`QR` ou `LOCALIZACAO`) e vínculo com a avaliação que a usou (vazio até ser usada). Cada avaliação aponta para no máximo uma visita, e cada visita é usada por no máximo uma avaliação.
- **Janela de validade**: a visita libera avaliação por **24 horas** depois do check-in. Depois disso, ou depois de usada, ela não libera mais nada. Não existe tempo mínimo entre o check-in e a avaliação. **Um check-in por usuário e local a cada 24 horas**: com a visita da janela já usada, um check-in novo é recusado até a janela passar (sem isso, ler o mesmo QR de novo, ou uma foto dele, dava avaliações ilimitadas).
- **Campo novo no `Estabelecimento`: token de check-in**, separado do `codigoAcesso`. O `codigoAcesso` é a chave da equipe e também confirma a edição e a remoção de administradores, então **nunca** pode ir num QR impresso. O token segue a mesma proteção de serialização do `codigoAcesso`: nunca sai no JSON por padrão, só é revelado ao dono. Ele é gerado na criação, e os estabelecimentos que já existem ganham um token por uma migração idempotente no boot (mesmo padrão das migrações de status e de pontos acumulados).
- **Conteúdo do QR**: uma URL para a página de avaliação do site levando o id do estabelecimento **e** o token de check-in. A câmera normal do celular abre o site (a web não precisa de leitor). O leitor do mobile, que já extrai o id do estabelecimento da URL, passa a ler também o token. QRs antigos, só com o id, continuam abrindo a página, mas não confirmam visita, e o cliente cai na opção por localização.
- **Endpoint de check-in**: recebe usuário, estabelecimento e **ou** o token **ou** as coordenadas do aparelho.
  - Token: precisa ser igual ao token atual do estabelecimento.
  - Localização: a distância até as coordenadas salvas do estabelecimento precisa ser de no máximo **200 m** (Haversine, a mesma conta que a web e o mobile já usam em "perto de você"). Um estabelecimento sem coordenadas recusa o check-in por localização com uma mensagem específica.
  - Em caso de sucesso, devolve o id da visita e quando ela expira. Um novo check-in enquanto o usuário tem uma visita aberta no mesmo lugar devolve a visita existente em vez de criar outra.
- **Dono gera novo token de check-in**: mesmo padrão do "gerar novo código" (só o dono, com confirmação no painel). Os QRs impressos antigos param de confirmar visitas na hora.
- **Criar avaliação passa a exigir uma visita válida.** A requisição leva o id da visita. O servidor confere se ela é do mesmo usuário e do mesmo estabelecimento, se não expirou e se não foi usada, e então faz o vínculo. As mensagens de erro dizem qual foi o caso (nenhuma visita, expirada, já usada). O método fica gravado na avaliação para aparecer como selo.
- **Sai o fallback para o convidado padrão compartilhado**: avaliação sem id de usuário é recusada. Quem chega pelo QR como convidado já ganha uma conta de convidado própria na chegada, e a visita fica ligada a essa conta.
- O **limite mensal do plano** (`validarNovoFeedback`) continua rodando como hoje, depois da checagem da visita.

### Recusa com motivo

- **Campos novos na `Avaliacao`: motivo da recusa** (texto, obrigatório quando o status vai para recusado, sem espaços nas pontas, com **pelo menos 10 caracteres**) e **data da decisão**, gravada em **qualquer** mudança de status (implementado, recusado ou de volta para pendente), não só na recusa. É ela que mede a agilidade da Transparência, inclusive quando o estabelecimento aceita rápido sem escrever nada.
- **Transições de status permitidas, garantidas pelo servidor** (hoje só o desktop restringe): pendente → implementado; pendente → recusado (motivo obrigatório); recusado → pendente (apaga o motivo). Qualquer outra transição é recusada. Implementado é final, porque já creditou pontos.
- O contrato de mudar status passa a ser `{status, idAdmin, motivo}`. O `idAdmin` mantém a checagem de equipe feita na correção de permissão.
- O motivo da recusa é público: sai junto com a avaliação na listagem do estabelecimento e na lista do autor.
- Invariantes que continuam como estão e agora ficam registradas aqui: sugestões recusadas continuam públicas e contando na média; o estabelecimento não tem rota para apagar avaliação.
- As telas que recusam (lista de sugestões e detalhes do estabelecimento no desktop, admin do site, admin do mobile) pedem o motivo antes de enviar. As telas que mostram sugestões ("minhas sugestões" e página do estabelecimento no site; "minhas sugestões" e informações do local no mobile) mostram o motivo.

### Reputação

- **Novo `ReputacaoService`**, só calculado, sem tabela (mesma abordagem do `ConquistaService`), alimentado por consultas agregadas sobre as avaliações.
- **Cliente — Confiabilidade (0–100)**:
  - **Só entram na conta as avaliações com visita vinculada.** Como a visita passa a ser obrigatória, isso é exatamente o conjunto das avaliações feitas depois do lançamento. As anteriores não contam nem a favor nem contra, e não é preciso guardar uma data de corte em configuração.
  - `aceitacao` = aceitas / (aceitas + recusadas), entre as que entram na conta; as pendentes não contam
  - pontuação = round(100 × `aceitacao`)
  - menos de **3** avaliações decididas (aceitas + recusadas) na conta → `Novo`, sem número
  - O antigo componente `verificadas` (fatia com visita confirmada) sai: se só as avaliações com visita entram na conta, ele seria sempre 100% e não diria nada.
- **Estabelecimento — Transparência (0–100)**:
  - `resposta` = avaliações que receberam resposta pública ou saíram de pendente / total
  - `recusa` = recusadas / decididas
  - `agilidade` = 1 se o tempo médio até a primeira reação (resposta escrita ou data da decisão, a que vier antes) for de até 48 h, caindo linearmente até 0 em 14 dias
  - pontuação = round(40 × `resposta` + 40 × (1 − `recusa`) + 20 × `agilidade`)
  - menos de **5** avaliações → `Sem dados suficientes`
- **Formato da resposta** (os dois): `{ pontuacao | null, rotulo, componentes: {...números brutos...}, total }`. Os componentes sempre vão junto, por transparência.
- **Endpoints**: reputação do usuário e reputação do estabelecimento, os dois públicos (não têm dado pessoal).
- A listagem de sugestões do painel ganha a Confiabilidade do autor ao lado do nível que já aparece. As consultas são feitas em lote para os autores da lista, e não uma por sugestão.
- Onde aparece: os perfis de cliente da web e do mobile ganham um card de Confiabilidade; as páginas públicas do estabelecimento na web e no mobile ganham um card de Transparência; o painel admin do desktop mostra a Transparência de cada estabelecimento.

### Telas envolvidas

- **Web (cliente)**: página de avaliação (check-in pelo token da URL ou pela localização, depois o envio com a visita), página do estabelecimento (selo, motivo da recusa, Transparência), minhas sugestões (motivo), perfil (Confiabilidade).
- **Mobile (cliente)**: leitor de QR (lê também o token), check-in por localização antes do formulário de sugestão, as mesmas exibições da web.
- **Desktop (admin)**: motivo ao recusar, exibição do QR de check-in com impressão e geração de novo, Confiabilidade do autor na lista, Transparência do estabelecimento.
- **Admin do site e admin do mobile**: motivo ao recusar, Confiabilidade do autor.

## Testing Decisions

- **O que faz um bom teste aqui**: ele exercita a regra pela entrada pública do service (fazer check-in, enviar avaliação, mudar status, calcular reputação) e confere o resultado observável (o que foi salvo, que erro voltou, que pontuação saiu). Não confere qual método interno foi chamado, a não ser para garantir que algo **não** foi salvo ou creditado num caminho que precisa ser barrado.
- **Pontos de teste (os menos possíveis, todos no nível dos services):**
  1. **Check-in e envio da avaliação**: testes unitários com Mockito no service que cria a visita e em `AvaliacaoService.registrarNovaAvaliacao`. Casos: token certo, token errado, localização dentro e fora dos 200 m, estabelecimento sem coordenadas, visita expirada, já usada, de outro usuário ou de outro local, check-in repetido reaproveitando a visita aberta. Referência: `AvaliacaoServiceTest`.
  2. **Mudar status com motivo**: amplia o `AvaliacaoServiceTest`. Casos: recusar sem motivo ou com motivo curto, recusar com motivo válido, recusado → pendente apaga o motivo, transições não permitidas, checagem de equipe continua valendo. Referência: o mesmo arquivo.
  3. **Reputação**: `@DataJpaTest` contra H2 em memória, porque as fórmulas dependem de consultas agregadas e um mock esconderia o SQL de verdade. Casos: cada fórmula com dados conhecidos, os limites de `Novo` e `Sem dados suficientes`, pendentes não contando na aceitação, e avaliações sem visita (as antigas) não mudando a Confiabilidade, nem para cima nem para baixo. Referência: `PontosAcumuladosTest`.
  4. **Serialização do token de check-in** (nunca sai por padrão, só é revelado ao dono): o mesmo tipo de teste do `EstabelecimentoTest`.
  5. **Migração do token** para os estabelecimentos existentes, idempotente: no mesmo estilo do teste de migração do `PontosAcumuladosTest`.
- **Frontends**: sem testes automatizados (o projeto não tem nenhum). Verificações: build do desktop, checagem de sintaxe dos arquivos web alterados, `flutter analyze` quando o SDK permitir e uma demonstração manual (história 37).
- **Cuidado com a suíte completa**: o `BackendApplicationTests` sobe contra o MySQL real com `ddl-auto=update`, então as colunas e tabelas novas são criadas no banco real quando a suíte roda. São mudanças só de acréscimo, mas quem rodar a suíte precisa saber disso.

## Out of Scope

- **QR que muda sozinho** (um código que troca a cada poucos minutos numa tela no balcão). Um token fixo que o dono pode trocar basta por agora.
- **Detecção de GPS falsificado**. A localização é aceita como o método mais fraco, e o método gravado permite ver quais avaliações vieram de cada um.
- **Ponderar a média pela reputação do autor** ou pelas visitas confirmadas. A média continua simples, sobre todas as avaliações.
- **Contestar uma recusa** junto à plataforma.
- **Autenticação de verdade** (JWT). A identidade continua sendo o id enviado pelo cliente, como nas correções de permissão já feitas.
- **Tempo mínimo entre o check-in e a avaliação**.
- **Níveis e recompensas** ligados à reputação (multiplicador, nível mínimo) ficam para um spec separado.
- **Avaliação de funcionários** e **validação de cupom no caixa**, cada uma no seu próprio spec.
- QR de check-in no admin do site e no admin do mobile (nesta entrega, só no desktop).

## Further Notes

### Decisões para revisar antes dos tickets

São as decisões de maior impacto. Cada uma traz a alternativa que foi descartada:

1. **Visita obrigatória** para avaliar, em vez de só um selo nas avaliações que tiverem. O obrigatório responde ao "confirmar antes de liberar", mas bloqueia quem não conseguir fazer check-in. Só o selo seria mais brando e não resolveria o problema que a banca apontou.
2. **Localização aceita como alternativa ao QR.** Sem ela, estabelecimentos que não imprimirem o QR ficariam sem avaliações. O ponto fraco é que dá para falsificar o GPS.
3. **Janela de 24 h, uma avaliação por visita.** Poderia ser menor, como 6 h, ou permitir mais de uma avaliação por visita.
4. **Raio de 200 m.** Os endereços geocodificados pelo serviço Nominatim podem errar por dezenas de metros. 100 m seria mais rigoroso e recusaria mais gente que está no local.
5. **Token de check-in separado em vez do `codigoAcesso`.** Essa não está em discussão: reaproveitar colocaria a chave da equipe nas mesas.
6. **Fim do fallback para o convidado compartilhado.** É necessário para a exigência fazer sentido, mas uma avaliação enviada com a API fora do ar vai falhar em vez de sair como o convidado genérico.
7. **Motivo mínimo de 10 caracteres** para recusar.
8. **Fórmulas e limites da reputação** (Confiabilidade = 100 × aceitação; pesos 40/40/20 na Transparência; 3 decididas e 5 avaliações como mínimo; 48 h e 14 dias como limites de agilidade). São números simples e fáceis de explicar; dá para ajustar sem mudar o desenho.
9. **Recusado → pendente apaga o motivo.** A alternativa seria guardar um histórico de recusas, que dá mais trabalho.
10. **Confiabilidade só com avaliações feitas depois do lançamento, identificadas pela visita vinculada.** Com isso a pontuação passa a medir só a aceitação. Alternativa: pesar o método da visita (QR vale mais que localização), por exemplo 70 × aceitação + 30 × fatia por QR. Isso mantém um sinal da força da confirmação, mas prejudica quem frequenta lugares que não imprimem QR.

### Riscos conhecidos

- QRs de demonstração já impressos (como o `qrcode-suggesto-feira.png`) só levam o id: na feira, o cliente vai precisar da localização ou de um QR gerado de novo.
- Como as avaliações antigas não contam, logo depois do lançamento praticamente todos os clientes aparecem como "Novo". A Confiabilidade só ganha número depois de 3 avaliações novas decididas. Para a demonstração, vale preparar dados com visita.
- O site e o mobile precisam ser publicados junto com o backend, porque a mudança no contrato de envio de avaliação quebra os apps antigos.
