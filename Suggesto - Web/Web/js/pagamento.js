/* =========================================================
   PAGAMENTO — Suggesto
   Tela de checkout de demonstração.

   ATENÇÃO: nenhum dado é enviado para servidor algum e nenhum
   pagamento real é processado. Tudo acontece no navegador,
   apenas para fins de apresentação do projeto.
========================================================= */


// ===== DADOS DOS PLANOS =====
const PLANOS = {
  'Básico': {
    mensal: 49,
    anual: 39,
    descricao: 'Para pequenos negócios que estão começando a ouvir seus clientes.',
    beneficios: [
      '1 estabelecimento cadastrado',
      'Até 200 feedbacks por mês',
      'Painel de gerenciamento básico',
      'Suporte por e-mail'
    ]
  },
  'Pro': {
    mensal: 119,
    anual: 95,
    descricao: 'Para negócios em crescimento que querem transformar dados em decisões.',
    beneficios: [
      'Até 3 estabelecimentos',
      'Feedbacks ilimitados',
      'Painel completo com métricas',
      'Relatórios e estatísticas',
      'Sistema de recompensas'
    ]
  },
  'Empresarial': {
    mensal: 299,
    anual: 239,
    descricao: 'Para redes e grupos com múltiplas unidades que precisam de controle total.',
    beneficios: [
      'Estabelecimentos ilimitados',
      'Feedbacks ilimitados',
      'Relatórios avançados',
      'Múltiplos administradores',
      'Suporte prioritário 24/7'
    ]
  }
};

// Cupons aceitos na demonstração
const CUPONS = {
  'SUGGESTO10': { desconto: 0.10, texto: 'Cupom SUGGESTO10 (10%)' },
  'PROJETO25':  { desconto: 0.25, texto: 'Cupom PROJETO25 (25%)' }
};


// ===== ESTADO =====
let planoAtual = sessionStorage.getItem('planoEscolhido') || 'Pro';
let periodoAtual = sessionStorage.getItem('periodoEscolhido') || 'mensal';
let metodoAtual = 'cartao';
let cupomAplicado = null;

// Se o plano guardado não existir, volta para a página de planos
if (!PLANOS[planoAtual]) {
  window.location.href = 'planos.html';
}


// ===== ATALHOS =====
const $ = (id) => document.getElementById(id);

const inputNumero   = $('numeroCartao');
const inputNome     = $('nomeCartao');
const inputValidade = $('validadeCartao');
const inputCvv      = $('cvvCartao');
const inputCpf      = $('cpfTitular');
const cartaoVisual  = $('cartaoVisual');


/* =========================================================
   FORMATAÇÃO DE VALORES
========================================================= */
function formatarReal(valor) {
  return valor.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  });
}


/* =========================================================
   RESUMO DO PEDIDO
========================================================= */
function calcularValores() {
  const plano = PLANOS[planoAtual];
  const mensalidade = periodoAtual === 'anual' ? plano.anual : plano.mensal;

  // No plano anual cobramos 12 meses de uma vez
  const meses = periodoAtual === 'anual' ? 12 : 1;
  const base = plano.mensal * meses;
  const comDesconto = mensalidade * meses;
  const descontoAnual = base - comDesconto;

  const descontoCupom = cupomAplicado
    ? comDesconto * CUPONS[cupomAplicado].desconto
    : 0;

  return {
    mensalidade,
    meses,
    base,
    descontoAnual,
    descontoCupom,
    total: comDesconto - descontoCupom
  };
}

function atualizarResumo() {
  const plano = PLANOS[planoAtual];
  const v = calcularValores();

  // Cabeçalho
  $('resumoPlano').textContent = 'Plano ' + planoAtual;
  $('resumoDescricao').textContent = plano.descricao;
  $('tituloPlano').textContent = planoAtual;

  // Benefícios
  $('resumoBeneficios').innerHTML = plano.beneficios
    .map(b => `<li><i class="fas fa-check"></i>${b}</li>`)
    .join('');

  // Opções de período
  $('labelMensalValor').textContent = `${formatarReal(plano.mensal)}/mês`;
  $('labelAnualValor').textContent  = `${formatarReal(plano.anual)}/mês`;
  $('opcaoMensal').classList.toggle('ativa', periodoAtual === 'mensal');
  $('opcaoAnual').classList.toggle('ativa', periodoAtual === 'anual');

  // Linha base
  $('resumoLabelBase').textContent =
    `Plano ${planoAtual} (${periodoAtual === 'anual' ? '12 meses' : 'mensal'})`;
  $('resumoValorBase').textContent = formatarReal(v.base);

  // Desconto anual
  const linhaAnual = $('linhaDescontoAnual');
  if (v.descontoAnual > 0) {
    linhaAnual.hidden = false;
    $('valorDescontoAnual').textContent = '- ' + formatarReal(v.descontoAnual);
  } else {
    linhaAnual.hidden = true;
  }

  // Desconto do cupom
  const linhaCupom = $('linhaDescontoCupom');
  if (v.descontoCupom > 0) {
    linhaCupom.hidden = false;
    $('labelDescontoCupom').textContent = CUPONS[cupomAplicado].texto;
    $('valorDescontoCupom').textContent = '- ' + formatarReal(v.descontoCupom);
  } else {
    linhaCupom.hidden = true;
  }

  // Total após o teste grátis
  $('totalDepois').textContent = periodoAtual === 'anual'
    ? `depois ${formatarReal(v.total)}/ano`
    : `depois ${formatarReal(v.total)}/mês`;

  // Valor do PIX (à vista, sem período de teste)
  $('pixValor').textContent = formatarReal(v.total);

  atualizarParcelas();
  gerarCodigoPix();
}

function definirPeriodo(periodo) {
  periodoAtual = periodo;
  sessionStorage.setItem('periodoEscolhido', periodo);
  atualizarResumo();
}


/* =========================================================
   PARCELAMENTO
========================================================= */
function atualizarParcelas() {
  const v = calcularValores();
  const select = $('parcelas');
  const maximo = periodoAtual === 'anual' ? 12 : 1;

  select.innerHTML = '';

  for (let i = 1; i <= maximo; i++) {
    const valorParcela = v.total / i;
    const opcao = document.createElement('option');
    opcao.value = i;
    opcao.textContent = i === 1
      ? `À vista — ${formatarReal(v.total)}`
      : `${i}x de ${formatarReal(valorParcela)} sem juros`;
    select.appendChild(opcao);
  }
}


/* =========================================================
   CUPOM
========================================================= */
function aplicarCupom() {
  const campo = $('cupom');
  const retorno = $('cupomRetorno');
  const codigo = campo.value.trim().toUpperCase();

  retorno.classList.add('visivel');

  if (!codigo) {
    cupomAplicado = null;
    retorno.className = 'cupom-retorno visivel erro';
    retorno.textContent = 'Digite um cupom para aplicar.';
    atualizarResumo();
    return;
  }

  if (CUPONS[codigo]) {
    cupomAplicado = codigo;
    retorno.className = 'cupom-retorno visivel ok';
    retorno.innerHTML = `<i class="fas fa-check"></i> Cupom aplicado com sucesso!`;
  } else {
    cupomAplicado = null;
    retorno.className = 'cupom-retorno visivel erro';
    retorno.textContent = 'Cupom inválido ou expirado.';
  }

  atualizarResumo();
}


/* =========================================================
   ABAS DE MÉTODO
========================================================= */
function trocarMetodo(metodo) {
  metodoAtual = metodo;

  $('abaCartao').classList.toggle('ativa', metodo === 'cartao');
  $('abaPix').classList.toggle('ativa', metodo === 'pix');

  $('painelCartao').classList.toggle('ativo', metodo === 'cartao');
  $('painelPix').classList.toggle('ativo', metodo === 'pix');
}


/* =========================================================
   BANDEIRAS DO CARTÃO
   (identificadas pelos prefixos públicos de cada emissor)
========================================================= */
function detectarBandeira(numero) {
  const n = numero.replace(/\D/g, '');

  if (/^4/.test(n)) return { nome: 'Visa', cvv: 3 };
  if (/^(5[1-5]|2[2-7])/.test(n)) return { nome: 'Mastercard', cvv: 3 };
  if (/^3[47]/.test(n)) return { nome: 'Amex', cvv: 4 };
  if (/^(4011|4312|4389|5041|5067|509|6277|6362|650)/.test(n)) return { nome: 'Elo', cvv: 3 };
  if (/^(606282|3841)/.test(n)) return { nome: 'Hipercard', cvv: 3 };
  if (/^(30[0-5]|36|38)/.test(n)) return { nome: 'Diners', cvv: 3 };

  return null;
}


/* =========================================================
   VALIDAÇÕES
========================================================= */

// Mesmo truque das maquininhas de cartão: pega os números de trás pra
// frente, dobra um número sim um não, soma tudo. Se não for múltiplo de
// 10, o cartão digitado está errado — sem nem precisar consultar o banco.
function validarLuhn(numero) {
  const n = numero.replace(/\D/g, '');
  if (n.length < 13) return false;

  let soma = 0;
  let dobrar = false;

  for (let i = n.length - 1; i >= 0; i--) {
    let digito = parseInt(n[i], 10);

    if (dobrar) {
      digito *= 2;
      if (digito > 9) digito -= 9;
    }

    soma += digito;
    dobrar = !dobrar;
  }

  return soma % 10 === 0;
}

function validarValidade(texto) {
  const partes = texto.split('/');
  if (partes.length !== 2 || partes[1].length !== 2) return false;

  const mes = parseInt(partes[0], 10);
  const ano = 2000 + parseInt(partes[1], 10);

  if (isNaN(mes) || isNaN(ano) || mes < 1 || mes > 12) return false;

  const hoje = new Date();
  const ultimoDia = new Date(ano, mes, 0, 23, 59, 59);

  return ultimoDia >= hoje;
}

// Mesma ideia de um código de barras: cada número do CPF "pesa" um valor
// diferente numa conta, e o resultado tem que bater com os 2 últimos
// dígitos.
function validarCpf(texto) {
  const cpf = texto.replace(/\D/g, '');

  if (cpf.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false;

  for (let t = 9; t < 11; t++) {
    let soma = 0;
    for (let i = 0; i < t; i++) {
      soma += parseInt(cpf[i], 10) * (t + 1 - i);
    }
    let digito = (soma * 10) % 11;
    if (digito === 10) digito = 0;
    if (digito !== parseInt(cpf[t], 10)) return false;
  }

  return true;
}

function mostrarErro(campo, mensagem) {
  const input = $(campo);
  const erro = $('erro' + campo.charAt(0).toUpperCase() + campo.slice(1));

  input.classList.add('input-erro');
  input.classList.remove('input-ok');

  if (erro) {
    erro.textContent = mensagem;
    erro.classList.add('visivel');
  }
}

function limparErro(campo, valido) {
  const input = $(campo);
  const erro = $('erro' + campo.charAt(0).toUpperCase() + campo.slice(1));

  input.classList.remove('input-erro');
  input.classList.toggle('input-ok', valido === true);

  if (erro) erro.classList.remove('visivel');
}


/* =========================================================
   CARTÃO VISUAL — preenchimento em tempo real
========================================================= */

// Só "pinta" de novo os números que acabaram de ser digitados, comparando
// com o que já estava na tela antes — como destacar só a palavra nova que
// alguém acabou de escrever, sem grifar a frase inteira de novo.
function pintarNumeroCartao(valor) {
  const digitos = valor.replace(/\D/g, '');
  const bandeira = detectarBandeira(digitos);
  const total = bandeira && bandeira.nome === 'Amex' ? 15 : 16;

  const container = $('cartaoNumero');
  const anteriores = Array.from(container.querySelectorAll('span:not(.esp)'))
    .map(s => s.textContent);

  container.innerHTML = '';

  // Grupos: Amex usa 4-6-5, os demais usam 4-4-4-4
  const grupos = total === 15 ? [4, 6, 5] : [4, 4, 4, 4];
  let indice = 0;

  grupos.forEach((tamanho, g) => {
    for (let i = 0; i < tamanho; i++) {
      const span = document.createElement('span');
      const caractere = digitos[indice] || '•';
      span.textContent = caractere;

      // Anima só quando o dígito acabou de ser digitado
      if (caractere !== '•' && anteriores[indice] !== caractere) {
        span.classList.add('novo');
      }

      container.appendChild(span);
      indice++;
    }

    if (g < grupos.length - 1) {
      const espaco = document.createElement('span');
      espaco.className = 'esp';
      container.appendChild(espaco);
    }
  });
}

function aplicarMascaraCartao(valor) {
  const digitos = valor.replace(/\D/g, '').slice(0, 16);
  const bandeira = detectarBandeira(digitos);

  // Amex tem formatação própria (4-6-5)
  if (bandeira && bandeira.nome === 'Amex') {
    const n = digitos.slice(0, 15);
    return [n.slice(0, 4), n.slice(4, 10), n.slice(10, 15)]
      .filter(Boolean)
      .join(' ');
  }

  return digitos.replace(/(\d{4})(?=\d)/g, '$1 ');
}

// Número do cartão
inputNumero.addEventListener('input', (e) => {
  e.target.value = aplicarMascaraCartao(e.target.value);
  pintarNumeroCartao(e.target.value);

  const bandeira = detectarBandeira(e.target.value);
  const alvoBandeira = $('cartaoBandeira');
  const iconeCampo = $('iconeBandeira');

  if (bandeira) {
    alvoBandeira.innerHTML = `<span class="nome-bandeira">${bandeira.nome}</span>`;
    iconeCampo.textContent = bandeira.nome;
    inputCvv.maxLength = bandeira.cvv;
    inputCvv.placeholder = '0'.repeat(bandeira.cvv);
  } else {
    alvoBandeira.innerHTML = '<i class="fas fa-wifi cartao-nfc"></i>';
    iconeCampo.textContent = '';
    inputCvv.maxLength = 4;
  }

  limparErro('numeroCartao');
});

// Nome do titular
inputNome.addEventListener('input', (e) => {
  // Remove números e símbolos, mantendo acentos
  e.target.value = e.target.value.replace(/[^a-zA-ZÀ-ÿ\s'.]/g, '');

  const nome = e.target.value.trim();
  $('cartaoNome').textContent = nome || 'NOME COMO NO CARTÃO';

  limparErro('nomeCartao');
});

// Validade
inputValidade.addEventListener('input', (e) => {
  let v = e.target.value.replace(/\D/g, '').slice(0, 4);

  // Corrige mês digitado errado (ex.: "9" vira "09")
  if (v.length === 1 && parseInt(v, 10) > 1) v = '0' + v;
  if (v.length >= 2) {
    const mes = parseInt(v.slice(0, 2), 10);
    if (mes === 0) v = '01' + v.slice(2);
    if (mes > 12) v = '12' + v.slice(2);
  }

  if (v.length > 2) v = v.slice(0, 2) + '/' + v.slice(2);

  e.target.value = v;
  $('cartaoValidade').textContent = v || 'MM/AA';

  limparErro('validadeCartao');
});

// CVV — vira o cartão
inputCvv.addEventListener('input', (e) => {
  e.target.value = e.target.value.replace(/\D/g, '');
  $('cartaoCvv').textContent = e.target.value || '•••';
  limparErro('cvvCartao');
});

inputCvv.addEventListener('focus', () => {
  cartaoVisual.classList.add('virado');
  destacarCampo(null);
});

inputCvv.addEventListener('blur', () => {
  cartaoVisual.classList.remove('virado');
});

// CPF
inputCpf.addEventListener('input', (e) => {
  let v = e.target.value.replace(/\D/g, '').slice(0, 11);
  v = v.replace(/(\d{3})(\d)/, '$1.$2');
  v = v.replace(/(\d{3})(\d)/, '$1.$2');
  v = v.replace(/(\d{3})(\d{1,2})$/, '$1-$2');
  e.target.value = v;
  limparErro('cpfTitular');
});


// ===== DESTAQUE DO CAMPO ATIVO NO CARTÃO =====
function destacarCampo(campo) {
  document.querySelectorAll('[data-campo]').forEach(el => {
    el.classList.toggle('focado', el.dataset.campo === campo);
  });
}

inputNumero.addEventListener('focus',   () => destacarCampo('numero'));
inputNome.addEventListener('focus',     () => destacarCampo('nome'));
inputValidade.addEventListener('focus', () => destacarCampo('validade'));

[inputNumero, inputNome, inputValidade].forEach(campo => {
  campo.addEventListener('blur', () => destacarCampo(null));
});


/* =========================================================
   ENVIO DO FORMULÁRIO
========================================================= */
$('formCartao').addEventListener('submit', (e) => {
  e.preventDefault();

  let valido = true;

  // Número
  if (!validarLuhn(inputNumero.value)) {
    mostrarErro('numeroCartao', 'Número de cartão inválido. Confira os dígitos.');
    valido = false;
  } else {
    limparErro('numeroCartao', true);
  }

  // Nome
  if (inputNome.value.trim().length < 3 || !inputNome.value.trim().includes(' ')) {
    mostrarErro('nomeCartao', 'Digite o nome completo como aparece no cartão.');
    valido = false;
  } else {
    limparErro('nomeCartao', true);
  }

  // Validade
  if (!validarValidade(inputValidade.value)) {
    mostrarErro('validadeCartao', 'Data inválida ou cartão vencido.');
    valido = false;
  } else {
    limparErro('validadeCartao', true);
  }

  // CVV
  const bandeira = detectarBandeira(inputNumero.value);
  const tamanhoCvv = bandeira ? bandeira.cvv : 3;
  if (inputCvv.value.length !== tamanhoCvv) {
    mostrarErro('cvvCartao', `O CVV deve ter ${tamanhoCvv} dígitos.`);
    valido = false;
  } else {
    limparErro('cvvCartao', true);
  }

  // CPF
  if (!validarCpf(inputCpf.value)) {
    mostrarErro('cpfTitular', 'CPF inválido.');
    valido = false;
  } else {
    limparErro('cpfTitular', true);
  }

  if (!valido) {
    mostrarToast('Confira os campos destacados antes de continuar.');
    document.querySelector('.input-erro')?.focus();
    return;
  }

  processarPagamento('Cartão de crédito');
});


/* =========================================================
   PROCESSAMENTO (SIMULADO)
========================================================= */
function processarPagamento(metodo) {
  const botao = metodo === 'PIX'
    ? document.querySelector('#painelPix .botao-principal')
    : $('btnPagar');

  if (botao) botao.classList.add('carregando');

  // Simula o tempo de resposta de uma operadora
  setTimeout(() => {
    if (botao) botao.classList.remove('carregando');

    const v = calcularValores();

    $('reciboId').textContent = '#SGT-' +
      Math.floor(100000 + Math.random() * 900000);
    $('reciboMetodo').textContent = metodo;

    if (metodo === 'PIX') {
      $('reciboValor').textContent = formatarReal(v.total);
      $('sucessoTexto').innerHTML =
        `Recebemos seu PIX e a assinatura do plano <strong>${planoAtual}</strong> ` +
        `já está ativa. Agora é só criar a conta do seu estabelecimento.`;
    } else {
      $('reciboValor').textContent =
        `${formatarReal(0)} hoje · depois ${formatarReal(v.total)}`;
      $('sucessoTexto').innerHTML =
        `Sua assinatura do plano <strong>${planoAtual}</strong> foi confirmada e ` +
        `seus 14 dias de teste grátis começaram. Agora é só criar a conta do seu estabelecimento.`;
    }

    // Guarda o resumo para as próximas telas (e para o histórico da demonstração)
    sessionStorage.setItem('pagamentoConfirmado', JSON.stringify({
      plano: planoAtual,
      periodo: periodoAtual,
      metodo: metodo,
      valor: v.total,
      data: new Date().toISOString()
    }));

    $('sucessoOverlay').classList.add('visivel');
  }, 1900);
}

function simularPix() {
  processarPagamento('PIX');
}

function irParaCadastro() {
  window.location.href = 'cadastroAdm.html';
}


/* =========================================================
   PIX — QR Code e código fictícios
========================================================= */

// Essa tela é só uma demonstração — não é um QR code de pagamento real.
// Os quadradinhos "aleatórios" vêm de uma fórmula que sempre começa do
// mesmo número, tipo um dado viciado que cai sempre na mesma sequência.
// Assim o desenho fica sempre igual, só pra mostrar a ideia da tela.
function desenharQrFalso() {
  const canvas = $('pixQr');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const modulos = 29;
  const tamanho = canvas.width / modulos;

  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#0e0e12';

  // Gerador pseudoaleatório com semente fixa, para o desenho não mudar a cada frame
  let semente = 20260825;
  const aleatorio = () => {
    semente = (semente * 9301 + 49297) % 233280;
    return semente / 233280;
  };

  // Marcadores de canto (os três quadrados grandes)
  const cantos = [[0, 0], [modulos - 7, 0], [0, modulos - 7]];
  const ehCanto = (x, y) => cantos.some(([cx, cy]) =>
    x >= cx && x < cx + 7 && y >= cy && y < cy + 7
  );

  cantos.forEach(([cx, cy]) => {
    ctx.fillRect(cx * tamanho, cy * tamanho, 7 * tamanho, 7 * tamanho);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect((cx + 1) * tamanho, (cy + 1) * tamanho, 5 * tamanho, 5 * tamanho);
    ctx.fillStyle = '#0e0e12';
    ctx.fillRect((cx + 2) * tamanho, (cy + 2) * tamanho, 3 * tamanho, 3 * tamanho);
  });

  // Módulos aleatórios no restante da área
  for (let y = 0; y < modulos; y++) {
    for (let x = 0; x < modulos; x++) {
      if (ehCanto(x, y)) continue;

      // Deixa o centro livre para a logo
      const centro = Math.abs(x - modulos / 2) < 3 && Math.abs(y - modulos / 2) < 3;
      if (centro) continue;

      if (aleatorio() > 0.52) {
        ctx.fillRect(x * tamanho, y * tamanho, tamanho, tamanho);
      }
    }
  }
}

// Monta um código no formato visual do "copia e cola" do PIX (fictício)
function gerarCodigoPix() {
  const v = calcularValores();
  const valor = v.total.toFixed(2);

  const codigo =
    '00020126580014BR.GOV.BCB.PIX0136' +
    'suggesto-demo-' + planoAtual.toLowerCase().replace(/[^a-z]/g, '') +
    '5204000053039865802BR5908SUGGESTO6009SAO PAULO' +
    '54' + String(valor.length).padStart(2, '0') + valor +
    '62070503***6304DEMO';

  const campo = $('pixCodigo');
  if (campo) campo.value = codigo;
}

function copiarPix() {
  const campo = $('pixCodigo');
  campo.select();

  navigator.clipboard.writeText(campo.value)
    .then(() => mostrarToast('Código PIX copiado!', true))
    .catch(() => {
      document.execCommand('copy');
      mostrarToast('Código PIX copiado!', true);
    });
}

// Contagem regressiva do PIX
function iniciarContadorPix() {
  let restante = 15 * 60;
  const alvo = $('pixTempo');

  setInterval(() => {
    if (restante <= 0) {
      alvo.textContent = 'expirado';
      return;
    }

    restante--;
    const min = String(Math.floor(restante / 60)).padStart(2, '0');
    const seg = String(restante % 60).padStart(2, '0');
    alvo.textContent = `${min}:${seg}`;
  }, 1000);
}


/* =========================================================
   TOAST
========================================================= */
let temporizadorToast;

function mostrarToast(mensagem, sucesso = false) {
  const toast = $('toast');

  toast.textContent = mensagem;
  toast.classList.toggle('sucesso', sucesso);
  toast.classList.add('visivel');

  clearTimeout(temporizadorToast);
  temporizadorToast = setTimeout(() => {
    toast.classList.remove('visivel');
  }, 3000);
}


/* =========================================================
   INICIALIZAÇÃO
========================================================= */
atualizarResumo();
desenharQrFalso();
iniciarContadorPix();
