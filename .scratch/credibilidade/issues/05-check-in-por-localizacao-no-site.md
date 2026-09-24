# 05: Check-in por localização no site

**What to build:** Quem está no estabelecimento mas não tem o QR confirma a visita pela localização do navegador: o site pede a posição, e o servidor aceita se ela estiver a até 200 m das coordenadas do estabelecimento.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] A rota de check-in aceita coordenadas no lugar do token e confirma se a distância (Haversine) for de no máximo 200 m, com método LOCALIZACAO
- [ ] Longe demais é recusado com mensagem que diz a distância aproximada
- [ ] Estabelecimento sem coordenadas recusa o check-in por localização com mensagem específica
- [ ] A página de avaliação do site oferece "Estou aqui" quando não veio token pela URL
- [ ] Permissão de localização negada ou indisponível mostra uma mensagem sugerindo o QR
- [ ] Testes cobrem dentro e fora do raio e estabelecimento sem coordenadas
