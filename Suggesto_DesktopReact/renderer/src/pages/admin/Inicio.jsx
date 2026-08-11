import React, { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import {
  API_BASE,
  buscarMetricas,
  formatarData,
  labelStatus,
  tituloSugestao,
} from "../../api/admin";
import "./Inicio.css";

const FAIXAS = [
  { id: "pendente", chave: "pendentes", desc: "Aguardando triagem" },
  { id: "implementado", chave: "implementados", desc: "Aprovadas e executadas" },
  { id: "recusado", chave: "recusados", desc: "Não aprovadas" },
];

export default function Inicio() {
  const [metricas, setMetricas] = useState(null);
  const [erro, setErro] = useState(null);
  const [carregando, setCarregando] = useState(true);

  useEffect(() => {
    let vivo = true;
    buscarMetricas()
      .then((m) => vivo && setMetricas(m))
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));
    return () => {
      vivo = false;
    };
  }, []);

  const faixas = useMemo(() => {
    if (!metricas) return [];
    const total = metricas.totalSugestoes || 0;
    return FAIXAS.map((f) => {
      const qtd = metricas[f.chave] || 0;
      return { ...f, qtd, pct: total ? (qtd / total) * 100 : 0 };
    });
  }, [metricas]);

  const categorias = useMemo(() => {
    const mapa = metricas?.porCategoria || {};
    const lista = Object.entries(mapa).sort((a, b) => b[1] - a[1]);
    const maior = lista[0]?.[1] || 1;
    return lista.slice(0, 5).map(([nome, qtd]) => ({ nome, qtd, pct: (qtd / maior) * 100 }));
  }, [metricas]);

  const porMes = metricas?.sugestoesPorMes || [];
  const maiorMes = Math.max(1, ...porMes.map((m) => m.total || 0));

  if (carregando) return <EstadoCarregando />;
  if (erro) return <EstadoErro mensagem={erro} />;

  const total = metricas.totalSugestoes || 0;

  return (
    <>
      <Topo
        titulo="Início"
        sub={`Panorama de ${total} ${total === 1 ? "sugestão recebida" : "sugestões recebidas"}`}
      >
        <Link to="/sugestoes" className="adm-btn adm-btn-principal">
          Triar sugestões
          <Icone d={IC.seta} size={14} />
        </Link>
      </Topo>

      {/* KPIs — larguras propositalmente desiguais: o destaque manda mais */}
      <div className="ini-kpis">
        <div className="ini-kpi ini-kpi-destaque">
          <p className="ini-kpi-rot">Novas nos últimos 7 dias</p>
          <p className="ini-kpi-val adm-num">{metricas.novasSemana ?? 0}</p>
          <p className="ini-kpi-sub">
            de {total} no total · {metricas.totalEstabelecimentos ?? 0}{" "}
            {metricas.totalEstabelecimentos === 1 ? "estabelecimento" : "estabelecimentos"}
          </p>
        </div>
        {faixas.map((f) => (
          <div key={f.id} className={`ini-kpi st-${f.id}`}>
            <p className="ini-kpi-rot">{labelStatus(f.id)}</p>
            <p className="ini-kpi-val adm-num">{f.qtd}</p>
            <p className="ini-kpi-sub">{f.pct.toFixed(1)}% do total</p>
          </div>
        ))}
      </div>

      <div className="ini-grade">
        <div className="ini-col">
          {/* Distribuição por status */}
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Distribuição por status</h2>
              <span className="adm-cartao-nota adm-num">{total} no total</span>
            </div>

            {total === 0 ? (
              <p className="adm-vazio">Nenhuma sugestão registrada ainda.</p>
            ) : (
              <>
                <div className="ini-barra">
                  {faixas
                    .filter((f) => f.qtd > 0)
                    .map((f) => (
                      <span
                        key={f.id}
                        className={`ini-barra-parte st-${f.id}`}
                        style={{ width: `${f.pct}%` }}
                        title={`${labelStatus(f.id)}: ${f.qtd}`}
                      />
                    ))}
                </div>

                <ul className="ini-status-lista">
                  {faixas.map((f) => (
                    <li key={f.id} className={`ini-status st-${f.id}`}>
                      <span className="adm-pill">{labelStatus(f.id)}</span>
                      <span className="ini-status-desc">{f.desc}</span>
                      <span className="ini-status-num adm-num">{f.qtd}</span>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </section>

          {/* Sugestões recentes */}
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Chegaram por último</h2>
              <Link to="/sugestoes" className="ini-link">
                Ver todas <Icone d={IC.seta} size={13} />
              </Link>
            </div>

            {(metricas.sugestoesRecentes || []).length === 0 ? (
              <p className="adm-vazio">Nada novo por aqui.</p>
            ) : (
              <ul className="ini-recentes">
                {metricas.sugestoesRecentes.map((s) => (
                  <li key={s.id} className={`ini-recente st-${s.statusUi}`}>
                    <div className="ini-recente-topo">
                      <span className="adm-pill">{labelStatus(s.statusUi)}</span>
                      <span className="ini-recente-tempo">
                        {formatarData(s.dataAvaliacao)}
                      </span>
                    </div>
                    <p className="ini-recente-txt">{tituloSugestao(s.comentario)}</p>
                    <p className="ini-recente-meta">
                      {s.categoria || "Sem categoria"}
                      {s.estabelecimento && <> · {s.estabelecimento}</>}
                      {s.autor && <> · {s.autor}</>}
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="ini-col">
          {/* Volume por mês — dado real de metricas.sugestoesPorMes */}
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Volume por mês</h2>
              <span className="adm-cartao-nota">últimos {porMes.length}</span>
            </div>
            {porMes.length === 0 ? (
              <p className="adm-vazio">Sem histórico.</p>
            ) : (
              <div className="ini-spark">
                {porMes.map((m, i) => (
                  <div key={`${m.mes}-${i}`} className="ini-spark-col">
                    <span className="ini-spark-val adm-num">{m.total}</span>
                    <span
                      className={`ini-spark-barra${i === porMes.length - 1 ? " atual" : ""}`}
                      style={{ height: `${Math.max(3, ((m.total || 0) / maiorMes) * 100)}%` }}
                    />
                    <span className="ini-spark-mes">{m.mes}</span>
                  </div>
                ))}
              </div>
            )}
          </section>

          {/* Categorias mais citadas */}
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Assuntos mais citados</h2>
            </div>
            {categorias.length === 0 ? (
              <p className="adm-vazio">Sem categorias registradas.</p>
            ) : (
              <ul className="ini-cats">
                {categorias.map((c) => (
                  <li key={c.nome} className="ini-cat">
                    <div className="ini-cat-topo">
                      <span className="ini-cat-nome">{c.nome}</span>
                      <span className="ini-cat-num adm-num">{c.qtd}</span>
                    </div>
                    <span className="ini-cat-trilho">
                      <span className="ini-cat-fill" style={{ width: `${c.pct}%` }} />
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>

          {/* Base de usuários */}
          <section className="adm-cartao ini-base">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Base</h2>
            </div>
            <dl className="ini-base-lista">
              <div>
                <dt>Clientes</dt>
                <dd className="adm-num">{metricas.totalUsuarios ?? 0}</dd>
              </div>
              <div>
                <dt>Administradores</dt>
                <dd className="adm-num">{metricas.totalAdmins ?? 0}</dd>
              </div>
              <div>
                <dt>Resgates de recompensa</dt>
                <dd className="adm-num">{metricas.totalResgates ?? 0}</dd>
              </div>
            </dl>
          </section>
        </div>
      </div>
    </>
  );
}

export function EstadoCarregando() {
  return <p className="adm-vazio">Carregando…</p>;
}

export function EstadoErro({ mensagem }) {
  return (
    <div className="adm-erro">
      Não foi possível falar com a API ({mensagem}). Verifique se o backend está
      respondendo em {API_BASE.replace("/api", "")}.
    </div>
  );
}
