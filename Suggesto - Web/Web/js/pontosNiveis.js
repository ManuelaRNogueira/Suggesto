/**
 * Régua oficial de níveis Suggesto (compartilhada entre loja e perfil).
 */
const PONTOS_NIVEIS = [
  { id: "bronze", nome: "Bronze", min: 0, max: 1000 },
  { id: "prata", nome: "Prata", min: 1001, max: 5000 },
  { id: "ouro", nome: "Ouro", min: 5001, max: 15000 },
  { id: "platina", nome: "Platina", min: 15001, max: null }
];

// Funciona como um cartão fidelidade com carimbos: primeiro descobre em
// qual faixa de pontos a pessoa está (bronze, prata, ouro...), depois
// calcula quanto falta pra encher essa faixa e passar pra próxima.
function calcularNivel(pontos) {
  const pts = Math.max(0, Number(pontos) || 0);

  for (const nivel of PONTOS_NIVEIS) {
    const dentroMax = nivel.max === null || pts <= nivel.max;
    if (pts >= nivel.min && dentroMax) {
      const proximo = PONTOS_NIVEIS[PONTOS_NIVEIS.indexOf(nivel) + 1] || null;
      return { atual: nivel, proximo, pontos: pts };
    }
  }

  return { atual: PONTOS_NIVEIS[0], proximo: PONTOS_NIVEIS[1], pontos: pts };
}

function calcularProgressoNivel(pontos) {
  const { atual, proximo, pontos: pts } = calcularNivel(pontos);

  if (!proximo) {
    return {
      atual,
      proximo: null,
      percentual: 100,
      pontosNoNivel: pts - atual.min,
      pontosParaProximo: 0,
      faltaParaProximo: 0,
      metaProximo: null
    };
  }

  const inicio = atual.min;
  const fim = proximo.min;
  const faixa = fim - inicio;
  const pontosNoNivel = Math.max(0, pts - inicio);
  const percentual = faixa > 0 ? Math.min(100, Math.round((pontosNoNivel / faixa) * 100)) : 0;
  const faltaParaProximo = Math.max(0, fim - pts);

  return {
    atual,
    proximo,
    percentual,
    pontosNoNivel,
    pontosParaProximo: faixa,
    faltaParaProximo,
    metaProximo: fim
  };
}

function formatarPontos(valor) {
  return Number(valor || 0).toLocaleString("pt-BR");
}

function classeNivel(idNivel) {
  return `nivel-${idNivel}`;
}

function beneficiosPorNivel(idNivel) {
  const mapa = {
    bronze: ["Acesso ao mercado de pontos", "Badge Bronze no perfil"],
    prata: ["Prioridade nas respostas", "Badge Prata no perfil", "Ofertas exclusivas"],
    ouro: ["Prioridade nas respostas", "Badge exclusivo no perfil", "Desconto em parceiros"],
    platina: ["Máxima prioridade", "Badge Platina", "Benefícios VIP em parceiros"]
  };
  return mapa[idNivel] || mapa.bronze;
}
