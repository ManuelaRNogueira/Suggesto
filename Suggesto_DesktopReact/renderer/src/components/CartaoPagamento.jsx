import React, { useState } from "react";
import "./CartaoPagamento.css";

// Mesma lógica de bandeiras do checkout do site (js/pagamento.js), só que em
// React: identifica a bandeira pelos prefixos públicos de cada emissor.
function detectarBandeira(numero) {
  const n = numero.replace(/\D/g, "");
  if (/^4/.test(n)) return { nome: "Visa", cvv: 3 };
  if (/^(5[1-5]|2[2-7])/.test(n)) return { nome: "Mastercard", cvv: 3 };
  if (/^3[47]/.test(n)) return { nome: "Amex", cvv: 4 };
  if (/^(4011|4312|4389|5041|5067|509|6277|6362|650)/.test(n)) return { nome: "Elo", cvv: 3 };
  if (/^(606282|3841)/.test(n)) return { nome: "Hipercard", cvv: 3 };
  if (/^(30[0-5]|36|38)/.test(n)) return { nome: "Diners", cvv: 3 };
  return null;
}

function aplicarMascaraCartao(valor) {
  const digitos = valor.replace(/\D/g, "").slice(0, 16);
  const bandeira = detectarBandeira(digitos);
  if (bandeira && bandeira.nome === "Amex") {
    const n = digitos.slice(0, 15);
    return [n.slice(0, 4), n.slice(4, 10), n.slice(10, 15)].filter(Boolean).join(" ");
  }
  return digitos.replace(/(\d{4})(?=\d)/g, "$1 ");
}

function aplicarMascaraValidade(valor) {
  let v = valor.replace(/\D/g, "").slice(0, 4);
  if (v.length === 1 && parseInt(v, 10) > 1) v = "0" + v;
  if (v.length >= 2) {
    const mes = parseInt(v.slice(0, 2), 10);
    if (mes === 0) v = "01" + v.slice(2);
    if (mes > 12) v = "12" + v.slice(2);
  }
  if (v.length > 2) v = v.slice(0, 2) + "/" + v.slice(2);
  return v;
}

// Esse é o mesmo truque que máquinas de cartão usam pra desconfiar de um
// número digitado errado antes mesmo de consultar o banco: pega os
// números de trás pra frente, dobra um número sim, um não, e soma tudo.
// Se o total não for múltiplo de 10, o número está errado.
function validarLuhn(numero) {
  const n = numero.replace(/\D/g, "");
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
  const partes = texto.split("/");
  if (partes.length !== 2 || partes[1].length !== 2) return false;
  const mes = parseInt(partes[0], 10);
  const ano = 2000 + parseInt(partes[1], 10);
  if (isNaN(mes) || isNaN(ano) || mes < 1 || mes > 12) return false;
  const hoje = new Date();
  const ultimoDia = new Date(ano, mes, 0, 23, 59, 59);
  return ultimoDia >= hoje;
}

function pintarNumeroCartao(valor, bandeira) {
  const digitos = valor.replace(/\D/g, "");
  const total = bandeira && bandeira.nome === "Amex" ? 15 : 16;
  const grupos = total === 15 ? [4, 6, 5] : [4, 4, 4, 4];
  const partes = [];
  let indice = 0;
  grupos.forEach((tamanho) => {
    let grupo = "";
    for (let i = 0; i < tamanho; i++) {
      grupo += digitos[indice] || "•";
      indice++;
    }
    partes.push(grupo);
  });
  return partes.join("  ");
}

export default function CartaoPagamento({ onConfirmar, carregando = false, textoBotao = "Confirmar assinatura" }) {
  const [numero, setNumero] = useState("");
  const [nome, setNome] = useState("");
  const [validade, setValidade] = useState("");
  const [cvv, setCvv] = useState("");
  const [virado, setVirado] = useState(false);
  const [focado, setFocado] = useState(null);
  const [erros, setErros] = useState({});

  const bandeira = detectarBandeira(numero);
  const tamanhoCvv = bandeira ? bandeira.cvv : 3;

  const handleSubmit = (e) => {
    e.preventDefault();

    const novosErros = {};
    if (!validarLuhn(numero)) novosErros.numero = "Número de cartão inválido. Confira os dígitos.";
    if (nome.trim().length < 3 || !nome.trim().includes(" ")) {
      novosErros.nome = "Digite o nome completo como aparece no cartão.";
    }
    if (!validarValidade(validade)) novosErros.validade = "Data inválida ou cartão vencido.";
    if (cvv.length !== tamanhoCvv) novosErros.cvv = `O CVV deve ter ${tamanhoCvv} dígitos.`;

    setErros(novosErros);
    if (Object.keys(novosErros).length > 0) return;

    onConfirmar?.({ numero, nome, validade, cvv });
  };

  return (
    <div className="cp-wrap">
      <div className="cp-cena">
        <div className={`cp-cartao${virado ? " cp-virado" : ""}`}>
          <div className="cp-face cp-frente">
            <div className="cp-brilho"></div>
            <div className="cp-topo">
              <div className="cp-chip">
                <span></span><span></span><span></span>
                <span></span><span></span><span></span>
              </div>
              <div className="cp-bandeira">
                {bandeira ? <span>{bandeira.nome}</span> : <Icone width={20} height={14} />}
              </div>
            </div>

            <div className={`cp-numero${focado === "numero" ? " cp-focado" : ""}`}>
              {pintarNumeroCartao(numero, bandeira)}
            </div>

            <div className="cp-base">
              <div className={`cp-campo${focado === "nome" ? " cp-focado" : ""}`}>
                <label>Titular do cartão</label>
                <span>{nome.trim() || "NOME COMO NO CARTÃO"}</span>
              </div>
              <div className={`cp-campo cp-campo-validade${focado === "validade" ? " cp-focado" : ""}`}>
                <label>Validade</label>
                <span>{validade || "MM/AA"}</span>
              </div>
            </div>
          </div>

          <div className="cp-face cp-verso">
            <div className="cp-tarja"></div>
            <div className="cp-assinatura">
              <div className="cp-assinatura-linha"></div>
              <div className="cp-cvv">{cvv || "•••"}</div>
            </div>
            <p className="cp-aviso">
              Cartão meramente ilustrativo. Este é um projeto acadêmico sem processamento real de pagamentos.
            </p>
          </div>
        </div>
      </div>

      <form className="cp-form" onSubmit={handleSubmit} noValidate>
        <div className="cp-campo-grupo">
          <label htmlFor="cpNumero">Número do cartão</label>
          <input
            id="cpNumero"
            type="text"
            inputMode="numeric"
            autoComplete="cc-number"
            placeholder="0000 0000 0000 0000"
            maxLength={23}
            value={numero}
            onChange={(e) => {
              setNumero(aplicarMascaraCartao(e.target.value));
              setErros((old) => ({ ...old, numero: undefined }));
            }}
            onFocus={() => setFocado("numero")}
            onBlur={() => setFocado(null)}
            className={erros.numero ? "cp-input-erro" : ""}
          />
          {erros.numero && <span className="cp-erro">{erros.numero}</span>}
        </div>

        <div className="cp-campo-grupo">
          <label htmlFor="cpNome">Nome impresso no cartão</label>
          <input
            id="cpNome"
            type="text"
            autoComplete="cc-name"
            placeholder="Como aparece no cartão"
            value={nome}
            onChange={(e) => {
              setNome(e.target.value.replace(/[^a-zA-ZÀ-ÿ\s'.]/g, "").toUpperCase());
              setErros((old) => ({ ...old, nome: undefined }));
            }}
            onFocus={() => setFocado("nome")}
            onBlur={() => setFocado(null)}
            className={erros.nome ? "cp-input-erro" : ""}
          />
          {erros.nome && <span className="cp-erro">{erros.nome}</span>}
        </div>

        <div className="cp-campo-linha">
          <div className="cp-campo-grupo">
            <label htmlFor="cpValidade">Validade</label>
            <input
              id="cpValidade"
              type="text"
              inputMode="numeric"
              autoComplete="cc-exp"
              placeholder="MM/AA"
              maxLength={5}
              value={validade}
              onChange={(e) => {
                setValidade(aplicarMascaraValidade(e.target.value));
                setErros((old) => ({ ...old, validade: undefined }));
              }}
              onFocus={() => setFocado("validade")}
              onBlur={() => setFocado(null)}
              className={erros.validade ? "cp-input-erro" : ""}
            />
            {erros.validade && <span className="cp-erro">{erros.validade}</span>}
          </div>

          <div className="cp-campo-grupo">
            <label htmlFor="cpCvv">CVV</label>
            <input
              id="cpCvv"
              type="text"
              inputMode="numeric"
              autoComplete="cc-csc"
              placeholder="000"
              maxLength={4}
              value={cvv}
              onChange={(e) => {
                setCvv(e.target.value.replace(/\D/g, ""));
                setErros((old) => ({ ...old, cvv: undefined }));
              }}
              onFocus={() => setVirado(true)}
              onBlur={() => setVirado(false)}
              className={erros.cvv ? "cp-input-erro" : ""}
            />
            {erros.cvv && <span className="cp-erro">{erros.cvv}</span>}
          </div>
        </div>

        <button type="submit" className="adm-btn adm-btn-principal cp-botao-pagar" disabled={carregando}>
          {carregando ? "Processando…" : textoBotao}
        </button>

        <p className="cp-nota">
          Dados fictícios — nenhum pagamento real é processado neste projeto acadêmico.
        </p>
      </form>
    </div>
  );
}

function Icone({ width, height }) {
  return (
    <svg width={width} height={height} viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth="2">
      <path d="M2 9.5h20" />
      <path d="M2 6a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z" />
    </svg>
  );
}
