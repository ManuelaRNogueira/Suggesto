# 04: Check-in por QR no site, com selo (visita ainda opcional)

**What to build:** Quem lê o QR de check-in com a câmera do celular cai na página de avaliação do site, e a visita é registrada automaticamente, inclusive para quem chega como convidado. A avaliação enviada com essa visita sai com o selo "Visita confirmada", visível na página do estabelecimento. Nesta etapa a visita ainda é **opcional**: avaliações sem visita continuam funcionando, para os apps que ainda não mandam a visita não quebrarem.

**Blocked by:** 03

**Status:** resolved

- [x] Existe a entidade Visita (usuário, estabelecimento, momento, método QR/LOCALIZACAO, avaliação que a usou)
- [x] Rota de check-in por token: token certo cria a visita e devolve o id e o horário de expiração; token errado é recusado
- [x] Um check-in repetido com uma visita aberta no mesmo lugar devolve a visita existente
- [x] A avaliação aceita um id de visita opcional. Quando vem, precisa ser do mesmo usuário e estabelecimento, não ter expirado (24 h) e não ter sido usada; aí fica vinculada e grava o método
- [x] Avaliação sem visita continua sendo aceita como hoje (a visita só vira obrigatória no ticket 07)
- [x] A página de avaliação do site lê o token da URL, faz o check-in na chegada (depois de garantir o convidado) e manda a visita no envio
- [x] QR antigo, só com o id, continua abrindo a página normalmente, sem visita
- [x] A página do estabelecimento mostra o selo "Visita confirmada" nas avaliações com visita, e as antigas aparecem sem selo
- [x] Testes cobrem token certo e errado, visita reaproveitada, expirada, já usada, e de outro usuário ou outro local

## Comments

- Rota de check-in: `POST /api/estabelecimentos/{id}/checkin` com `{idUsuario, token}`, devolve `{idVisita, expiraEm}`. A avaliação guarda `id_visita` (unique, uma visita libera uma avaliação) e copia o método em `metodoVisita`, que é o campo que vai no JSON e acende o selo. A página de avaliação agora abre o formulário só com o `id` (o QR não leva `nome`) e busca o nome na API. Se o check-in falhar, a página mostra o motivo em amarelo e a avaliação sai sem selo.
