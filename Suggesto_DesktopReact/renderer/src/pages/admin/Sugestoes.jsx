import React, { useEffect, useMemo, useState } from "react";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import { EstadoCarregando, EstadoErro } from "./Inicio";
import {
  atualizarStatusSugestao,
  buscarMeuPlano,
  buscarSugestoes,
  formatarData,
  iniciais,
  labelStatus,
  responderSugestao,
  STATUS,
  tituloSugestao,
} from "../../api/admin";
import "./Sugestoes.css";

const POR_PAGINA = 12;

// Transições oferecidas em cada estado. Estado final não oferece ação.
const ACOES = {
  pendente: ["implementado", "recusado"],
  implementado: [],
  recusado: ["pendente"],
};

export default function Sugestoes() {
  const [sugestoes, setSugestoes] = useState([]);
  const [erro, setErro] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [salvando, setSalvando] = useState(null);
  const [aviso, setAviso] = useState(null);
  const [podeExportar, setPodeExportar] = useState(true);

  const [respondendoId, setRespondendoId] = useState(null);
  const [textoResposta, setTextoResposta] = useState("");
  const [enviandoResposta, setEnviandoResposta] = useState(null);
  const meuId = localStorage.getItem("idUsuario");

  const [busca, setBusca] = useState("");
  const [status, setStatus] = useState("todos");
  const [categoria, setCategoria] = useState("todas");
  const [ordem, setOrdem] = useState("recente");
  const [pagina, setPagina] = useState(1);

  useEffect(() => {
    let vivo = true;
    buscarSugestoes()
      .then((lista) => vivo && setSugestoes(lista || []))
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));
    // Exportação de dados é um recurso de plano (ver planos.html).
    buscarMeuPlano()
      .then((p) => vivo && setPodeExportar(p.permiteExportacao !== false))
      .catch(() => {});
    return () => {
      vivo = false;
    };
  }, []);

  useEffect(() => {
    if (!aviso) return;
    const t = setTimeout(() => setAviso(null), 3200);
    return () => clearTimeout(t);
  }, [aviso]);

  useEffect(() => setPagina(1), [busca, status, categoria, ordem]);

  const contagens = useMemo(() => {
    const base = { todos: sugestoes.length };
    STATUS.forEach((s) => {
      base[s.id] = sugestoes.filter((x) => x.statusUi === s.id).length;
    });
    return base;
  }, [sugestoes]);

  const categorias = useMemo(() => {
    const mapa = new Map();
    sugestoes.forEach((s) => {
      const nome = s.categoria || "Sem categoria";
      mapa.set(nome, (mapa.get(nome) || 0) + 1);
    });
    return [...mapa.entries()].sort((a, b) => b[1] - a[1]);
  }, [sugestoes]);

  const filtradas = useMemo(() => {
    const termo = busca.trim().toLowerCase();
    const lista = sugestoes.filter((s) => {
      if (status !== "todos" && s.statusUi !== status) return false;
      if (categoria !== "todas" && (s.categoria || "Sem categoria") !== categoria)
        return false;
      if (!termo) return true;
      return [s.comentario, s.autor, s.estabelecimento, s.categoria]
        .filter(Boolean)
        .some((campo) => campo.toLowerCase().includes(termo));
    });

    const data = (s) => new Date(s.dataAvaliacao || 0).getTime();
    return [...lista].sort((a, b) => {
      if (ordem === "antigo") return data(a) - data(b);
      if (ordem === "nota") return (b.nota || 0) - (a.nota || 0);
      if (ordem === "az")
        return tituloSugestao(a.comentario).localeCompare(
          tituloSugestao(b.comentario),
          "pt-BR",
        );
      // Prioridade: clientes de nível mais alto sobem na fila; empate cai na data.
      if (ordem === "prioridade")
        return (b.prioridade || 1) - (a.prioridade || 1) || data(b) - data(a);
      return data(b) - data(a);
    });
  }, [sugestoes, busca, status, categoria, ordem]);

  const totalPaginas = Math.max(1, Math.ceil(filtradas.length / POR_PAGINA));
  const paginaAtual = Math.min(pagina, totalPaginas);
  const visiveis = filtradas.slice(
    (paginaAtual - 1) * POR_PAGINA,
    paginaAtual * POR_PAGINA,
  );

  const mudarStatus = async (sugestao, novo) => {
    const anterior = { status: sugestao.status, statusUi: sugestao.statusUi };
    setSalvando(sugestao.id);
    // atualização otimista — a lista responde na hora
    setSugestoes((prev) =>
      prev.map((s) =>
        s.id === sugestao.id ? { ...s, status: novo, statusUi: novo } : s,
      ),
    );
    try {
      await atualizarStatusSugestao(sugestao.id, novo);
      setAviso({ tipo: "ok", texto: `Marcada como "${labelStatus(novo)}".` });
    } catch (e) {
      // desfaz se a API recusar
      setSugestoes((prev) =>
        prev.map((s) => (s.id === sugestao.id ? { ...s, ...anterior } : s)),
      );
      setAviso({ tipo: "erro", texto: `Não foi possível atualizar: ${e.message}` });
    } finally {
      setSalvando(null);
    }
  };

  const abrirResposta = (sugestao) => {
    setRespondendoId(sugestao.id);
    setTextoResposta(sugestao.resposta || "");
  };

  const cancelarResposta = () => {
    setRespondendoId(null);
    setTextoResposta("");
  };

  const enviarResposta = async (sugestao) => {
    setEnviandoResposta(sugestao.id);
    try {
      const dados = await responderSugestao(sugestao.id, {
        idAdmin: meuId,
        resposta: textoResposta,
      });
      const salva = dados.avaliacao;
      setSugestoes((prev) =>
        prev.map((s) =>
          s.id === sugestao.id
            ? {
                ...s,
                resposta: salva.resposta,
                respondidoPor: salva.respondidoPor,
                dataResposta: salva.dataResposta,
              }
            : s,
        ),
      );
      setAviso({ tipo: "ok", texto: "Resposta enviada." });
      cancelarResposta();
    } catch (e) {
      setAviso({ tipo: "erro", texto: `Não foi possível enviar a resposta: ${e.message}` });
    } finally {
      setEnviandoResposta(null);
    }
  };

  const exportarCsv = () => {
    const cabecalho = [
      "id",
      "status",
      "nota",
      "categoria",
      "estabelecimento",
      "autor",
      "data",
      "comentario",
    ];
    const escapar = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const linhas = filtradas.map((s) =>
      [
        s.id,
        labelStatus(s.statusUi),
        s.nota ?? "",
        s.categoria ?? "",
        s.estabelecimento ?? "",
        s.autor ?? "",
        s.dataAvaliacao ?? "",
        s.comentario ?? "",
      ]
        .map(escapar)
        .join(","),
    );
    const csv = [cabecalho.join(","), ...linhas].join("\n");
    const url = URL.createObjectURL(new Blob([`﻿${csv}`], { type: "text/csv" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = `suggesto-sugestoes-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    setAviso({ tipo: "ok", texto: `${filtradas.length} linhas exportadas.` });
  };

  if (carregando) return <EstadoCarregando />;
  if (erro) return <EstadoErro mensagem={erro} />;

  return (
    <>
      <Topo
        titulo="Sugestões"
        sub={`${filtradas.length} de ${sugestoes.length} ${
          sugestoes.length === 1 ? "sugestão" : "sugestões"
        } em vista`}
      >
        <label className="sug-busca">
          <Icone d={IC.busca} size={14} />
          <input
            className="sug-busca-campo"
            type="search"
            placeholder="Buscar por texto, autor ou local…"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
          />
        </label>
        <button
          type="button"
          className="adm-btn"
          onClick={() =>
            podeExportar
              ? exportarCsv()
              : setAviso({ tipo: "erro", texto: "Exportar em CSV está disponível no plano Pro." })
          }
          disabled={podeExportar && filtradas.length === 0}
          title={podeExportar ? undefined : "Disponível no plano Pro"}
        >
          <Icone d={podeExportar ? IC.baixar : IC.cadeado} size={14} />
          CSV
        </button>
      </Topo>

      <div className="sug-filtros">
        <div className="sug-chips">
          <Chip
            ativo={status === "todos"}
            onClick={() => setStatus("todos")}
            rotulo="Todas"
            qtd={contagens.todos}
          />
          {STATUS.map((s) => (
            <Chip
              key={s.id}
              id={s.id}
              ativo={status === s.id}
              onClick={() => setStatus(s.id)}
              rotulo={s.label}
              qtd={contagens[s.id]}
            />
          ))}
        </div>
        <select
          className="adm-campo sug-ordem"
          value={ordem}
          onChange={(e) => setOrdem(e.target.value)}
        >
          <option value="recente">Mais recentes</option>
          <option value="prioridade">Prioridade (nível)</option>
          <option value="antigo">Mais antigas</option>
          <option value="nota">Maior nota</option>
          <option value="az">A–Z</option>
        </select>
      </div>

      <div className="sug-grade">
        <div className="sug-lista-col">
          {visiveis.length === 0 ? (
            <p className="adm-vazio">Nenhuma sugestão bate com esse filtro.</p>
          ) : (
            <ul className="sug-lista">
              {visiveis.map((s) => (
                <Cartao
                  key={s.id}
                  sugestao={s}
                  salvando={salvando === s.id}
                  onMudar={mudarStatus}
                  respondendo={respondendoId === s.id}
                  textoResposta={textoResposta}
                  enviandoResposta={enviandoResposta === s.id}
                  onAbrirResposta={abrirResposta}
                  onCancelarResposta={cancelarResposta}
                  onTextoRespostaChange={setTextoResposta}
                  onEnviarResposta={enviarResposta}
                />
              ))}
            </ul>
          )}

          {totalPaginas > 1 && (
            <nav className="sug-paginacao">
              <button
                type="button"
                className="adm-btn"
                onClick={() => setPagina((p) => p - 1)}
                disabled={paginaAtual === 1}
              >
                Anterior
              </button>
              <span className="sug-paginacao-info adm-num">
                {paginaAtual} / {totalPaginas}
              </span>
              <button
                type="button"
                className="adm-btn"
                onClick={() => setPagina((p) => p + 1)}
                disabled={paginaAtual === totalPaginas}
              >
                Próxima
              </button>
            </nav>
          )}
        </div>

        <aside className="sug-painel">
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Categoria</h2>
            </div>
            <ul className="sug-cats">
              <li>
                <button
                  type="button"
                  className={`sug-cat${categoria === "todas" ? " ativo" : ""}`}
                  onClick={() => setCategoria("todas")}
                >
                  Todas <span className="adm-num">{sugestoes.length}</span>
                </button>
              </li>
              {categorias.map(([nome, qtd]) => (
                <li key={nome}>
                  <button
                    type="button"
                    className={`sug-cat${categoria === nome ? " ativo" : ""}`}
                    onClick={() => setCategoria(nome)}
                  >
                    {nome} <span className="adm-num">{qtd}</span>
                  </button>
                </li>
              ))}
            </ul>
          </section>
        </aside>
      </div>

      {aviso && (
        <div className={`sug-aviso${aviso.tipo === "erro" ? " erro" : ""}`}>
          {aviso.texto}
        </div>
      )}
    </>
  );
}

function Chip({ id, ativo, onClick, rotulo, qtd }) {
  return (
    <button
      type="button"
      className={`sug-chip${ativo ? " ativo" : ""}${id ? ` st-${id}` : ""}`}
      onClick={onClick}
    >
      {id && <span className="sug-chip-ponto" />}
      {rotulo}
      <span className="sug-chip-num adm-num">{qtd}</span>
    </button>
  );
}

function Cartao({
  sugestao,
  salvando,
  onMudar,
  respondendo,
  textoResposta,
  enviandoResposta,
  onAbrirResposta,
  onCancelarResposta,
  onTextoRespostaChange,
  onEnviarResposta,
}) {
  const acoes = ACOES[sugestao.statusUi] || [];

  return (
    <li className={`sug-card st-${sugestao.statusUi}`}>
      <div className="sug-card-topo">
        <span className="adm-pill">{labelStatus(sugestao.statusUi)}</span>
        <span className="sug-card-id adm-num">#{sugestao.id}</span>
        {sugestao.nota != null && (
          <span className="sug-card-nota adm-num">
            <Icone d={IC.estrela} size={12} />
            {sugestao.nota}
          </span>
        )}
        <span className="sug-card-tempo">{formatarData(sugestao.dataAvaliacao)}</span>
      </div>

      <p className="sug-card-txt">{tituloSugestao(sugestao.comentario)}</p>

      <div className="sug-card-meta">
        <span className="sug-card-autor">
          <span className="sug-card-avatar">{iniciais(sugestao.autor)}</span>
          {sugestao.autor || "Autor desconhecido"}
          {sugestao.nivelAutor && sugestao.nivelAutor !== "bronze" && (
            <span className={`sug-nivel nivel-${sugestao.nivelAutor}`}>
              {sugestao.nivelAutorNome}
            </span>
          )}
        </span>
        <span className="sug-card-sep">·</span>
        <span>{sugestao.categoria || "Sem categoria"}</span>
        {sugestao.estabelecimento && (
          <>
            <span className="sug-card-sep">·</span>
            <span>{sugestao.estabelecimento}</span>
          </>
        )}
      </div>

      {sugestao.resposta && !respondendo && (
        <div className="sug-resposta">
          <div className="sug-resposta-topo">
            <span className="sug-resposta-rotulo">Sua resposta</span>
            <button
              type="button"
              className="sug-resposta-editar"
              onClick={() => onAbrirResposta(sugestao)}
            >
              Editar
            </button>
          </div>
          <p className="sug-resposta-texto">{sugestao.resposta}</p>
          {sugestao.respondidoPor && (
            <span className="sug-resposta-autor">
              por {sugestao.respondidoPor}
              {sugestao.dataResposta && ` · ${formatarData(sugestao.dataResposta)}`}
            </span>
          )}
        </div>
      )}

      {respondendo && (
        <div className="sug-resposta-form">
          <textarea
            className="sug-resposta-campo"
            placeholder="Escreva a resposta que o cliente vai ver…"
            value={textoResposta}
            onChange={(e) => onTextoRespostaChange(e.target.value)}
            rows={3}
            autoFocus
          />
          <div className="sug-resposta-acoes">
            <button
              type="button"
              className="adm-btn"
              onClick={onCancelarResposta}
              disabled={enviandoResposta}
            >
              Cancelar
            </button>
            <button
              type="button"
              className="adm-btn adm-btn-principal"
              onClick={() => onEnviarResposta(sugestao)}
              disabled={enviandoResposta || !textoResposta.trim()}
            >
              {enviandoResposta ? "Enviando…" : "Enviar resposta"}
            </button>
          </div>
        </div>
      )}

      {(acoes.length > 0 || (!sugestao.resposta && !respondendo)) && (
        <div className="sug-card-acoes">
          {!sugestao.resposta && !respondendo && (
            <button
              type="button"
              className="adm-btn"
              onClick={() => onAbrirResposta(sugestao)}
            >
              <Icone d={IC.chat} size={13} />
              Responder
            </button>
          )}
          {acoes.map((destino) => (
            <button
              key={destino}
              type="button"
              className={`adm-btn adm-btn-cor st-${destino}`}
              disabled={salvando}
              onClick={() => onMudar(sugestao, destino)}
            >
              <Icone
                d={
                  destino === "implementado"
                    ? IC.check
                    : destino === "recusado"
                      ? IC.x
                      : IC.relogio
                }
                size={13}
              />
              {destino === "pendente" ? "Reabrir" : labelStatus(destino)}
            </button>
          ))}
        </div>
      )}
    </li>
  );
}
