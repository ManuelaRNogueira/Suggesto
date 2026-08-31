import React, { useEffect, useMemo, useState } from "react";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import { EstadoCarregando, EstadoErro } from "./Inicio";
import {
  buscarMetricas,
  buscarSugestoes,
  labelStatus,
  tituloSugestao,
} from "../../api/admin";
import "./Estatisticas.css";

const PERIODOS = [3, 6, 12];

// Paleta de categorias: variações do roxo da marca + as cores semânticas
// que o projeto já usa. Nada de gradiente.
const CORES_CAT = ["#7B2FBE", "#9B59D0", "#60a5fa", "#22c55e", "#eab308", "#f59e0b"];

export default function Estatisticas() {
  const [meses, setMeses] = useState(6);
  const [visao, setVisao] = useState("tipo");
  const [metricas, setMetricas] = useState(null);
  const [sugestoes, setSugestoes] = useState([]);
  const [erro, setErro] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [estabelecimentoFiltro, setEstabelecimentoFiltro] = useState("todos");

  // Só faz sentido separar estatísticas por estabelecimento quando o admin
  // tem mais de um — com um só, "Todos" e o próprio local dão o mesmo número.
  const estabelecimentosDisponiveis = useMemo(() => {
    const mapa = new Map();
    sugestoes.forEach((s) => {
      if (s.estabelecimentoId == null) return;
      if (!mapa.has(s.estabelecimentoId)) {
        mapa.set(s.estabelecimentoId, { id: s.estabelecimentoId, nome: s.estabelecimento || "Estabelecimento" });
      }
    });
    return [...mapa.values()].sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));
  }, [sugestoes]);
  const multiplosEstabelecimentos = estabelecimentosDisponiveis.length > 1;

  // Busca as métricas e as sugestões ao mesmo tempo (Promise.all) e guarda
  // tudo sob uma bandeira chamada "vivo". Se o admin trocar de mês, mudar o
  // filtro ou sair dessa tela antes da resposta voltar do servidor, essa
  // bandeira já vai ter caído — e a gente não tenta mais atualizar uma tela
  // que não existe mais, evitando uma "atualização fantasma". É como não
  // atender o telefone de um pedido depois que o cliente já foi embora do
  // restaurante: o "return () => { vivo = false }" no final é o aviso de
  // que a tela foi fechada.
  useEffect(() => {
    let vivo = true;
    setCarregando(true);
    const idEstabelecimento = estabelecimentoFiltro === "todos" ? undefined : estabelecimentoFiltro;
    Promise.all([buscarMetricas(meses, idEstabelecimento), buscarSugestoes()])
      .then(([m, s]) => {
        if (!vivo) return;
        setMetricas(m);
        setSugestoes(s || []);
        setErro(null);
      })
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));
    return () => {
      vivo = false;
    };
  }, [meses, estabelecimentoFiltro]);

  // As sugestões (usadas nos gráficos calculados no cliente: notas, áreas,
  // ranking) vêm sempre completas — filtra aqui pelo mesmo estabelecimento
  // que já foi aplicado no lado do servidor para as métricas.
  const sugestoesFiltradas = useMemo(() => {
    if (estabelecimentoFiltro === "todos") return sugestoes;
    return sugestoes.filter((s) => s.estabelecimentoId === estabelecimentoFiltro);
  }, [sugestoes, estabelecimentoFiltro]);

  const porMes = metricas?.sugestoesPorMes || [];

  // Monta o resumo que alimenta os cartões de KPI lá no topo da tela. É um
  // useMemo porque esses cálculos só precisam rodar de novo quando os dados
  // (métricas, sugestões, meses) realmente mudam — não a cada vez que a tela
  // é redesenhada por qualquer outro motivo, tipo o mouse passando por cima
  // de um botão.
  const resumo = useMemo(() => {
    if (!metricas) return null;
    const total = metricas.totalSugestoes || 0;
    const implementados = metricas.implementados || 0;

    const noPeriodo = porMes.reduce((acc, m) => acc + (m.total || 0), 0);
    const mesAtual = porMes.at(-1)?.total ?? 0;
    const mesAnterior = porMes.at(-2)?.total ?? 0;
    // Compara o mês mais recente com o anterior pra saber se o número de
    // sugestões está subindo ou caindo — tipo comparar a conta de luz desse
    // mês com a do mês passado. Só faz essa comparação se existir um mês
    // anterior com valor maior que zero; senão seria dividir por zero, que
    // não dá pra fazer, então o resultado fica "null" (sem comparação).
    const variacao =
      mesAnterior > 0 ? ((mesAtual - mesAnterior) / mesAnterior) * 100 : null;

    // Nota média: soma a nota de cada sugestão avaliada e divide pela
    // quantidade de sugestões que realmente receberam nota (as sem nota nem
    // entram na conta). Se ninguém avaliou nada ainda, devolve "null" em vez
    // de tentar dividir por zero.
    const comNota = sugestoesFiltradas.filter((s) => typeof s.nota === "number");
    const notaMedia = comNota.length
      ? comNota.reduce((acc, s) => acc + s.nota, 0) / comNota.length
      : null;

    return {
      total,
      implementados,
      noPeriodo,
      variacao,
      notaMedia,
      avaliadas: comNota.length,
      taxa: total ? (implementados / total) * 100 : 0,
      mediaMes: porMes.length ? noPeriodo / porMes.length : 0,
    };
  }, [metricas, sugestoesFiltradas, porMes]);

  // O backend chama esse mapa de "porCategoria", mas ele agrupa por tipo de post
  // (Sugestão / Crítica / Elogio) — ver AdminService.classificarTipo.
  // Daqui pra baixo: soma quantos posts existem de cada tipo, ordena do que
  // tem mais pro que tem menos, transforma cada quantidade em porcentagem do
  // total (é o que vira o tamanho da fatia na rosca) e vai dando a cada tipo
  // uma cor da paleta, na ordem.
  const porTipo = useMemo(() => {
    const mapa = metricas?.porCategoria || {};
    const total = Object.values(mapa).reduce((a, b) => a + b, 0);
    return Object.entries(mapa)
      .sort((a, b) => b[1] - a[1])
      .map(([nome, qtd], i) => ({
        nome,
        qtd,
        pct: total ? (qtd / total) * 100 : 0,
        cor: CORES_CAT[i % CORES_CAT.length],
      }));
  }, [metricas]);

  // Áreas do feedback (Atendimento, Higiene, Ambiente...), contadas a partir da
  // própria lista de sugestões, que já traz a categoria de cada uma.
  // O cálculo é simples: pra cada sugestão, soma 1 na "gaveta" da categoria
  // dela; no final ordena da categoria mais citada pra menos citada e
  // transforma cada contagem em porcentagem do total, pra desenhar as barras
  // do tamanho certo.
  const porArea = useMemo(() => {
    const mapa = {};
    sugestoesFiltradas.forEach((s) => {
      const nome = s.categoria || "Sem categoria";
      mapa[nome] = (mapa[nome] || 0) + 1;
    });
    const total = sugestoesFiltradas.length;
    return Object.entries(mapa)
      .sort((a, b) => b[1] - a[1])
      .map(([nome, qtd]) => ({
        nome,
        qtd,
        pct: total ? (qtd / total) * 100 : 0,
      }));
  }, [sugestoesFiltradas]);

  // Ranking das 5 sugestões com a melhor nota. Ordena da nota mais alta pra
  // mais baixa; quando duas sugestões empatam na nota, desempata pela mais
  // recente das duas — como decidir um empate de prova olhando quem entregou
  // a resposta por último. useMemo aqui evita refazer essa ordenação toda
  // vez que a tela redesenha — só recalcula se a lista de sugestões mudar.
  const melhorAvaliadas = useMemo(
    () =>
      sugestoesFiltradas
        .filter((s) => typeof s.nota === "number")
        .sort(
          (a, b) =>
            b.nota - a.nota ||
            new Date(b.dataAvaliacao || 0) - new Date(a.dataAvaliacao || 0),
        )
        .slice(0, 5),
    [sugestoesFiltradas],
  );

  if (erro) return <EstadoErro mensagem={erro} />;
  if (!metricas || !resumo) return <EstadoCarregando />;

  const maiorMes = Math.max(1, ...porMes.map((m) => m.total || 0));
  const totalTipo = porTipo.reduce((a, c) => a + c.qtd, 0);

  return (
    <>
      <Topo
        titulo="Estatísticas"
        sub={`Janela de ${meses} ${meses === 1 ? "mês" : "meses"} · ${resumo.noPeriodo} ${
          resumo.noPeriodo === 1 ? "sugestão" : "sugestões"
        } no período`}
      >
        {multiplosEstabelecimentos && (
          <select
            className="adm-campo est-select-estab"
            value={estabelecimentoFiltro}
            onChange={(e) =>
              setEstabelecimentoFiltro(
                e.target.value === "todos" ? "todos" : Number(e.target.value),
              )
            }
          >
            <option value="todos">Todos os estabelecimentos</option>
            {estabelecimentosDisponiveis.map((es) => (
              <option key={es.id} value={es.id}>
                {es.nome}
              </option>
            ))}
          </select>
        )}
        <div className="est-periodos">
          {PERIODOS.map((p) => (
            <button
              key={p}
              type="button"
              className={`est-periodo${meses === p ? " ativo" : ""}`}
              onClick={() => setMeses(p)}
            >
              {p}m
            </button>
          ))}
        </div>
      </Topo>

      <div className="est-kpis">
        <Kpi rotulo="Sugestões no total" valor={resumo.total} />
        <Kpi
          rotulo="Implementadas"
          valor={resumo.implementados}
          cor="var(--verde)"
          nota={`${resumo.taxa.toFixed(1)}% de aproveitamento`}
        />
        <Kpi
          rotulo="Média por mês"
          valor={resumo.mediaMes.toFixed(1)}
          nota={
            resumo.variacao === null
              ? "sem mês anterior para comparar"
              : `${resumo.variacao >= 0 ? "↑" : "↓"} ${Math.abs(resumo.variacao).toFixed(0)}% vs. mês anterior`
          }
        />
        <Kpi
          rotulo="Nota média"
          valor={resumo.notaMedia === null ? "—" : resumo.notaMedia.toFixed(1)}
          cor="var(--laranja)"
          sufixo={resumo.notaMedia === null ? null : "/ 5"}
          nota={
            resumo.notaMedia === null
              ? "nenhuma sugestão com nota"
              : `sobre ${resumo.avaliadas} avaliadas`
          }
        />
      </div>

      <div className="est-grade">
        <div className="est-col">
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Sugestões recebidas por mês</h2>
              <span className="adm-cartao-nota adm-num">
                pico de {maiorMes}
              </span>
            </div>
            {porMes.length === 0 ? (
              <p className="adm-vazio">Sem histórico no período.</p>
            ) : (
              <div className="est-barras">
                {porMes.map((m, i) => (
                  <div key={`${m.mes}-${i}`} className="est-barra-grupo">
                    <span className="est-barra-val adm-num">{m.total}</span>
                    <span
                      className={`est-barra${i === porMes.length - 1 ? " atual" : ""}`}
                      style={{
                        height: `${Math.max(2, ((m.total || 0) / maiorMes) * 100)}%`,
                      }}
                      title={`${m.mes}: ${m.total}`}
                    />
                    <span className="est-barra-mes">{m.mes}</span>
                  </div>
                ))}
              </div>
            )}
          </section>

          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Acumulado no período</h2>
            </div>
            {porMes.length < 2 ? (
              <p className="adm-vazio">Período curto demais para uma curva.</p>
            ) : (
              <Acumulado dados={porMes} />
            )}
          </section>

          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Sugestões com melhor nota</h2>
              <span className="adm-cartao-nota">as 5 primeiras</span>
            </div>
            {melhorAvaliadas.length === 0 ? (
              <p className="adm-vazio">Nenhuma sugestão recebeu nota ainda.</p>
            ) : (
              <ol className="est-ranking">
                {melhorAvaliadas.map((s, i) => (
                  <li key={s.id} className={`est-rank st-${s.statusUi}`}>
                    <span className="est-rank-pos adm-num">{i + 1}</span>
                    <span className="est-rank-info">
                      <span className="est-rank-nome">
                        {tituloSugestao(s.comentario)}
                      </span>
                      <span className="est-rank-meta">
                        {s.categoria || "Sem categoria"} ·{" "}
                        {labelStatus(s.statusUi)}
                        {multiplosEstabelecimentos && s.estabelecimento && ` · ${s.estabelecimento}`}
                      </span>
                    </span>
                    <span className="est-rank-nota adm-num">
                      <Icone d={IC.estrela} size={12} />
                      {s.nota}
                    </span>
                  </li>
                ))}
              </ol>
            )}
          </section>
        </div>

        <div className="est-col">
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Distribuição</h2>
              <div className="est-periodos">
                <button
                  type="button"
                  className={`est-periodo${visao === "tipo" ? " ativo" : ""}`}
                  onClick={() => setVisao("tipo")}
                >
                  Tipo
                </button>
                <button
                  type="button"
                  className={`est-periodo${visao === "area" ? " ativo" : ""}`}
                  onClick={() => setVisao("area")}
                >
                  Categoria
                </button>
              </div>
            </div>

            {visao === "tipo" ? (
              porTipo.length === 0 ? (
                <p className="adm-vazio">Sem tipos registrados.</p>
              ) : (
                <>
                  <Rosca dados={porTipo} total={totalTipo} />
                  <ul className="est-legenda">
                    {porTipo.map((c) => (
                      <li key={c.nome}>
                        <span
                          className="est-legenda-cor"
                          style={{ background: c.cor }}
                        />
                        <span className="est-legenda-nome">{c.nome}</span>
                        <span className="est-legenda-pct adm-num">
                          {c.pct.toFixed(0)}%
                        </span>
                      </li>
                    ))}
                  </ul>
                </>
              )
            ) : porArea.length === 0 ? (
              <p className="adm-vazio">Nenhuma sugestão com categoria ainda.</p>
            ) : (
              <Areas dados={porArea} />
            )}
          </section>

          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Situação atual</h2>
            </div>
            <ul className="est-situacao">
              {[
                ["pendente", metricas.pendentes],
                ["implementado", metricas.implementados],
                ["recusado", metricas.recusados],
              ].map(([id, qtd]) => (
                <li key={id} className={`est-situacao-item st-${id}`}>
                  <span className="adm-pill">{labelStatus(id)}</span>
                  <span className="est-situacao-num adm-num">{qtd || 0}</span>
                </li>
              ))}
            </ul>
          </section>
        </div>
      </div>
    </>
  );
}

function Kpi({ rotulo, valor, sufixo, nota, cor }) {
  return (
    <div className="est-kpi">
      <p className="est-kpi-rot">{rotulo}</p>
      <p className="est-kpi-val adm-num" style={cor ? { color: cor } : undefined}>
        {valor}
        {sufixo && <span className="est-kpi-sufixo">{sufixo}</span>}
      </p>
      {nota && <p className="est-kpi-nota">{nota}</p>}
    </div>
  );
}

// Gráfico de linha com a curva "acumulada": em vez de mostrar quanto chegou
// em cada mês isoladamente (isso já tem no gráfico de barras logo acima),
// mostra o total que já se juntou até aquele mês — como um cofrinho que só
// enche, nunca esvazia. Também não usa biblioteca pronta: calculamos as
// coordenadas na mão e desenhamos ligando ponto a ponto, igual conectar os
// pontinhos numa folha de papel quadriculado.
function Acumulado({ dados }) {
  const L = 560;
  const A = 150;
  const pad = 18;

  // "soma" vai guardando o total corrido: a cada mês, soma o que chegou
  // naquele mês ao que já tinha se acumulado até o mês anterior. É por isso
  // que essa curva só sobe (ou fica no mesmo lugar) — ela nunca desce.
  let soma = 0;
  const acumulado = dados.map((m) => (soma += m.total || 0));
  const maior = Math.max(1, ...acumulado);

  // Converte cada valor acumulado numa posição (x, y) dentro do desenho:
  // x anda da esquerda pra direita conforme os meses passam, e y sobe quanto
  // maior for o valor acumulado em relação ao maior valor da série (por isso
  // dividir pelo "maior" no cálculo) — é a mesma ideia de marcar pontos num
  // papel milimetrado antes de traçar a linha com uma régua.
  const pontos = acumulado.map((v, i) => ({
    x: pad + (i / (acumulado.length - 1)) * (L - pad * 2),
    y: A - pad - (v / maior) * (A - pad * 2),
    v,
  }));

  // Junta os pontos numa única linha (o contorno da curva) e depois fecha
  // essa linha numa forma preenchida — a "área" sombreada por baixo dela —
  // descendo até a base do gráfico e voltando. É como passar um lápis de
  // cor por baixo de uma linha que já foi desenhada.
  const linha = pontos.map((p) => `${p.x} ${p.y}`).join(" L ");
  const area = `M ${pontos[0].x} ${A - pad} L ${linha} L ${pontos.at(-1).x} ${A - pad} Z`;

  return (
    <>
      <svg
        className="est-linha"
        viewBox={`0 0 ${L} ${A}`}
        preserveAspectRatio="none"
        role="img"
        aria-label="Total acumulado de sugestões no período"
      >
        <path d={area} fill="rgba(123, 47, 190,0.14)" />
        <path
          d={`M ${linha}`}
          fill="none"
          stroke="var(--roxo-claro)"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />
        {pontos.map((p, i) => (
          <circle key={i} cx={p.x} cy={p.y} r="3.5" fill="var(--roxo-claro)">
            <title>{`${dados[i].mes}: ${p.v} acumuladas`}</title>
          </circle>
        ))}
      </svg>
      <div className="est-linha-meses">
        {dados.map((m, i) => (
          <span key={`${m.mes}-${i}`}>{m.mes}</span>
        ))}
      </div>
    </>
  );
}

// Ranking das áreas do feedback. Barra horizontal em vez de rosca porque aqui são
// até 8 categorias com nomes longos ("Qualidade do produto"), volume em que a rosca
// fica ilegível. Série única: a escala é sobre o maior valor e a cor é só a da marca,
// já que quem carrega a identidade de cada linha é o próprio rótulo.
function Areas({ dados }) {
  const maior = Math.max(1, ...dados.map((d) => d.qtd));

  return (
    <ul className="est-areas">
      {dados.map((d) => (
        <li key={d.nome}>
          <div className="est-area-topo">
            <span className="est-area-nome">{d.nome}</span>
            <span className="est-area-qtd adm-num">{d.qtd}</span>
          </div>
          <div
            className="est-area-track"
            title={`${d.nome}: ${d.qtd} (${d.pct.toFixed(1)}%)`}
          >
            <span
              className="est-area-fill"
              style={{ width: `${(d.qtd / maior) * 100}%` }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}

// Não usamos nenhuma biblioteca pronta de gráfico — esse desenho de
// "rosca" é feito igual alguém desenharia com compasso: calcula o tamanho
// do círculo e pinta só o pedaço proporcional a cada porcentagem.
function Rosca({ dados, total }) {
  const R = 46;
  const circ = 2 * Math.PI * R;
  // "acumulado" vai guardando quanto do contorno do círculo já foi pintado
  // pelas fatias anteriores. É o que desloca o início de cada fatia nova pra
  // logo depois de onde a anterior terminou (o "strokeDashoffset" lá embaixo)
  // — como um ponteiro de relógio que vai girando e marcando por onde já
  // passou, pra fatia seguinte saber onde começar.
  let acumulado = 0;

  return (
    <div className="est-rosca-wrap">
      <svg viewBox="0 0 120 120" className="est-rosca" role="img" aria-label="Distribuição por categoria">
        <circle cx="60" cy="60" r={R} fill="none" stroke="var(--fundo-3)" strokeWidth="14" />
        {dados.map((c) => {
          const traco = (c.pct / 100) * circ;
          const deslocamento = -acumulado;
          acumulado += traco;
          return (
            <circle
              key={c.nome}
              cx="60"
              cy="60"
              r={R}
              fill="none"
              stroke={c.cor}
              strokeWidth="14"
              strokeDasharray={`${Math.max(0, traco - 1.5)} ${circ}`}
              strokeDashoffset={deslocamento}
              transform="rotate(-90 60 60)"
            >
              <title>{`${c.nome}: ${c.qtd} (${c.pct.toFixed(1)}%)`}</title>
            </circle>
          );
        })}
        <text x="60" y="57" textAnchor="middle" className="est-rosca-num">
          {total}
        </text>
        <text x="60" y="71" textAnchor="middle" className="est-rosca-rot">
          sugestões
        </text>
      </svg>
    </div>
  );
}
