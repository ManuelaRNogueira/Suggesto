# 05: Check-in por localização no site

**What to build:** Quem está no estabelecimento mas não tem o QR confirma a visita pela localização do navegador: o site pede a posição, e o servidor aceita se ela estiver a até 200 m das coordenadas do estabelecimento.

**Blocked by:** 04

**Status:** resolved

- [x] A rota de check-in aceita coordenadas no lugar do token e confirma se a distância (Haversine) for de no máximo 200 m, com método LOCALIZACAO
- [x] Longe demais é recusado com mensagem que diz a distância aproximada
- [x] Estabelecimento sem coordenadas recusa o check-in por localização com mensagem específica
- [x] A página de avaliação do site oferece "Estou aqui" quando não veio token pela URL
- [x] Permissão de localização negada ou indisponível mostra uma mensagem sugerindo o QR
- [x] Testes cobrem dentro e fora do raio e estabelecimento sem coordenadas

## Comments

- Mesma rota do QR (`POST /api/estabelecimentos/{id}/checkin`): sem `token`, usa `lat`/`lng`. A distância na mensagem é arredondada de 10 em 10 m (ou em km com uma casa). Na página, o botão "Estou aqui" aparece sempre que não veio token pela URL, inclusive para quem chega pela busca. A posição é pedida sem cache e com alta precisão. Geolocalização só funciona em HTTPS (o Render é) ou em localhost.
