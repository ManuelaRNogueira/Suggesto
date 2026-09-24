# 06: Check-in no app mobile

**What to build:** O app mobile passa a confirmar a visita pelos dois caminhos: o leitor de QR do app lê o token junto com o id, e quem não tem o QR pode confirmar pelo GPS, que o app já usa. A avaliação sai com a visita, e o selo aparece nas telas do app.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] O leitor de QR extrai também o token da URL e faz o check-in antes de abrir o formulário de sugestão
- [ ] Sem token (QR antigo ou sugestão aberta pela busca), o app oferece o check-in por GPS antes do formulário
- [ ] As mensagens de longe demais, sem permissão e sem coordenadas aparecem no app
- [ ] A avaliação é enviada com o id da visita
- [ ] As informações do local no app mostram o selo "Visita confirmada"
