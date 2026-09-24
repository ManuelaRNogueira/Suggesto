# 06: Check-in no app mobile

**What to build:** O app mobile passa a confirmar a visita pelos dois caminhos: o leitor de QR do app lê o token junto com o id, e quem não tem o QR pode confirmar pelo GPS, que o app já usa. A avaliação sai com a visita, e o selo aparece nas telas do app.

**Blocked by:** 05

**Status:** resolved

- [x] O leitor de QR extrai também o token da URL e faz o check-in antes de abrir o formulário de sugestão
- [x] Sem token (QR antigo ou sugestão aberta pela busca), o app oferece o check-in por GPS antes do formulário
- [x] As mensagens de longe demais, sem permissão e sem coordenadas aparecem no app
- [x] A avaliação é enviada com o id da visita
- [x] As informações do local no app mostram o selo "Visita confirmada"

## Comments

- O leitor lê o `t` da URL e passa para a `SugerirPage` (`tokenCheckin`), que faz o check-in ao abrir. Sem token, a tela mostra "Estou aqui: confirmar visita" (GPS com alta precisão; mensagens separadas para GPS desligado, permissão negada e falha). Longe demais e sem coordenadas vêm prontas do backend. Selo na lista de avaliações do `infoLocal`. Conferido com `flutter analyze` (sem erros), não rodei no aparelho. Obs.: o Flutter desta máquina (Dart 3.11.3) é mais velho que o `sdk: ^3.11.5` do pubspec; para analisar precisei afrouxar temporariamente.
