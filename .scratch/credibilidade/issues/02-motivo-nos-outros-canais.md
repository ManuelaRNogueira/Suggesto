# 02: Motivo da recusa no admin do site, no admin do mobile e no app do cliente

**What to build:** A mesma regra do ticket 01, levada para os outros canais: o admin do site e o admin do mobile pedem o motivo ao recusar, e o app mobile do cliente mostra o motivo das sugestões recusadas.

**Blocked by:** 01

**Status:** resolved

- [x] O admin do site pede o motivo ao recusar e mostra o erro da API se houver
- [x] O admin do mobile pede o motivo ao recusar e mostra o erro da API se houver
- [x] No mobile do cliente, "Minhas sugestões" e as informações do local mostram o motivo das recusadas
- [x] Nenhum canal consegue recusar sem motivo (a API do ticket 01 garante; aqui é só a interface)

## Comments

- Feito no commit `a7721a2`. O admin do mobile agora oferece só as transições que a API aceita (implementado é final), como no desktop e no site. A caixa de resposta das informações do local virou reutilizável e mostra o motivo em vermelho. `flutter analyze` rodou numa cópia com o SDK afrouxado: nenhum erro nos arquivos alterados.
