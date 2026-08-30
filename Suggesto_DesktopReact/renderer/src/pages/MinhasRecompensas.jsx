import React, { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Topo } from "../components/AdminShell";
import Icone, { IC } from "../components/Icones";
import { EstadoCarregando, EstadoErro } from "./admin/Inicio";
import { API_BASE, buscarMinhasEstabelecimentos, idGerente } from "../api/admin";
import "./MinhasRecompensas.css";

const RAIZ = API_BASE.replace("/api", "");

// A recompensa pode ter foto própria; sem ela, o cliente vê a do estabelecimento.
// Espelhamos a mesma regra aqui para o admin enxergar o que o cliente enxerga.
function urlFoto(recompensa) {
  const nome = recompensa.fotoPath || recompensa.estabelecimento?.fotoPath;
  if (!nome) return null;
  const limpo = String(nome).trim().replace(/^\/?uploads\//, "");
  if (/^https?:\/\//i.test(limpo)) return limpo;
  return `${RAIZ}/uploads/${limpo}`;
}

export default function MinhasRecompensas() {
  const navegar = useNavigate();
  const { id: idEstabParam } = useParams();
  const [estabelecimentos, setEstabelecimentos] = useState([]);
  const [idEstabelecimento, setIdEstabelecimento] = useState(idEstabParam || "");
  const [recompensas, setRecompensas] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState(null);
  const [aviso, setAviso] = useState(null);
  const [form, setForm] = useState({ nome: "", descricao: "", custoPontos: "" });
  const [foto, setFoto] = useState(null);
  const [excluindo, setExcluindo] = useState(null);
  const [trocandoFoto, setTrocandoFoto] = useState(null);

  const inputTroca = useRef(null);
  const alvoTroca = useRef(null);

  // Prévia da foto escolhida no formulário, liberada quando troca ou sai da tela.
  const previa = useMemo(() => (foto ? URL.createObjectURL(foto) : null), [foto]);
  useEffect(() => () => previa && URL.revokeObjectURL(previa), [previa]);

  useEffect(() => {
    const gerente = idGerente();
    if (!gerente) {
      setCarregando(false);
      return;
    }

    let vivo = true;
    (async () => {
      try {
        // Portfólio completo: os que possuo + os de que sou funcionária.
        const lista = await buscarMinhasEstabelecimentos();
        if (!vivo) return;
        setEstabelecimentos(lista || []);
        if (!idEstabParam && lista.length > 0) {
          setIdEstabelecimento(String(lista[0].idEstabelecimento));
        }
      } catch (e) {
        if (vivo) setErro(e.message);
      } finally {
        if (vivo) setCarregando(false);
      }
    })();
    return () => {
      vivo = false;
    };
  }, [idEstabParam]);

  useEffect(() => {
    if (!idEstabelecimento) {
      setRecompensas([]);
      return;
    }

    let vivo = true;
    (async () => {
      try {
        const r = await fetch(`${API_BASE}/recompensas/estabelecimento/${idEstabelecimento}`);
        if (!vivo) return;
        setRecompensas(r.ok ? await r.json() : []);
      } catch {
        if (vivo) setRecompensas([]);
      }
    })();
    return () => {
      vivo = false;
    };
  }, [idEstabelecimento]);

  const semEstabelecimentos = !carregando && estabelecimentos.length === 0;
  const lojaAtual = estabelecimentos.find(
    (e) => String(e.idEstabelecimento) === String(idEstabelecimento),
  );

  // Sobe a foto num segundo passo: a recompensa precisa existir para dar nome ao arquivo.
  async function enviarFoto(idRecompensa, arquivo) {
    const idSolicitante = localStorage.getItem("idUsuario");
    const corpo = new FormData();
    corpo.append("foto", arquivo);
    corpo.append("idSolicitante", idSolicitante);

    const r = await fetch(`${API_BASE}/recompensas/${idRecompensa}/foto?idSolicitante=${idSolicitante}`, {
      method: "POST",
      body: corpo,
    });
    const corpoResposta = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(corpoResposta.message || "Não foi possível salvar a foto.");
    return corpoResposta;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setAviso(null);
    if (!idEstabelecimento) return;

    setSalvando(true);
    try {
      const r = await fetch(`${API_BASE}/recompensas`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          nome: form.nome.trim(),
          descricao: form.descricao.trim(),
          custoPontos: Number(form.custoPontos),
          estabelecimentoId: Number(idEstabelecimento),
        }),
      });
      if (!r.ok) {
        const err = await r.json().catch(() => ({}));
        throw new Error(err.message || "Erro ao cadastrar.");
      }

      let nova = await r.json();
      if (foto) {
        try {
          nova = await enviarFoto(nova.id, foto);
        } catch (erroFoto) {
          // A recompensa já existe; só a foto falhou. Avisa sem descartar o resto.
          setAviso(`Recompensa criada, mas a foto não subiu: ${erroFoto.message}`);
        }
      }

      setRecompensas((prev) =>
        [...prev, nova].sort((a, b) => a.custoPontos - b.custoPontos),
      );
      setForm({ nome: "", descricao: "", custoPontos: "" });
      setFoto(null);
    } catch (err) {
      setAviso(err.message || "Erro ao salvar recompensa.");
    } finally {
      setSalvando(false);
    }
  };

  const pedirTrocaFoto = (idRecompensa) => {
    alvoTroca.current = idRecompensa;
    inputTroca.current?.click();
  };

  const handleTrocaFoto = async (e) => {
    const arquivo = e.target.files?.[0];
    const idRecompensa = alvoTroca.current;
    e.target.value = "";
    if (!arquivo || !idRecompensa) return;

    setAviso(null);
    setTrocandoFoto(idRecompensa);
    try {
      const atualizada = await enviarFoto(idRecompensa, arquivo);
      setRecompensas((prev) =>
        prev.map((rec) => (rec.id === idRecompensa ? atualizada : rec)),
      );
    } catch (err) {
      setAviso(err.message);
    } finally {
      setTrocandoFoto(null);
    }
  };

  const confirmarExclusao = async () => {
    const alvo = excluindo;
    if (!alvo) return;
    setExcluindo(null);
    try {
      const r = await fetch(`${API_BASE}/recompensas/${alvo.id}`, { method: "DELETE" });
      if (!r.ok) throw new Error("Erro ao excluir.");
      setRecompensas((prev) => prev.filter((rec) => rec.id !== alvo.id));
    } catch (err) {
      setAviso(err.message || "Erro de comunicação.");
    }
  };

  if (erro) return <EstadoErro mensagem={erro} />;
  if (carregando) return <EstadoCarregando />;

  return (
    <>
      <button type="button" className="adm-btn rec-btn-voltar" onClick={() => navegar(-1)}>
        <Icone d={IC.seta} size={13} className="rec-icone-voltar" />
        Voltar
      </button>

      <Topo
        titulo="Minhas recompensas"
        sub={
          semEstabelecimentos
            ? "Nenhum estabelecimento cadastrado"
            : `${recompensas.length} ${recompensas.length === 1 ? "recompensa" : "recompensas"} em ${lojaAtual?.nome || "—"}`
        }
      >
        {!semEstabelecimentos && (
          <select
            className="adm-campo rec-seletor"
            value={idEstabelecimento}
            onChange={(e) => setIdEstabelecimento(e.target.value)}
          >
            {estabelecimentos.map((e) => (
              <option key={e.idEstabelecimento} value={e.idEstabelecimento}>
                {e.nome}
              </option>
            ))}
          </select>
        )}
      </Topo>

      {semEstabelecimentos && (
        <div className="adm-erro" style={{ marginBottom: 18 }}>
          Cadastre pelo menos um estabelecimento antes de criar recompensas.
        </div>
      )}

      {aviso && (
        <div className="adm-erro" style={{ marginBottom: 18 }}>
          {aviso}
        </div>
      )}

      <div className="rec-grade">
        <section className="adm-cartao">
          <div className="adm-cartao-topo">
            <h2 className="adm-cartao-titulo">Novo brinde</h2>
          </div>

          <form onSubmit={handleSubmit} className="rec-form">
            <div>
              <label className="adm-rotulo" htmlFor="rec-nome">Nome do brinde</label>
              <input
                id="rec-nome"
                className="adm-campo"
                value={form.nome}
                onChange={(e) => setForm({ ...form, nome: e.target.value })}
                placeholder="Ex.: Casquinha grátis"
                required
                disabled={semEstabelecimentos}
              />
            </div>

            <div>
              <label className="adm-rotulo" htmlFor="rec-desc">Descrição</label>
              <textarea
                id="rec-desc"
                className="adm-campo rec-textarea"
                value={form.descricao}
                onChange={(e) => setForm({ ...form, descricao: e.target.value })}
                placeholder="Ex.: Uma casquinha de baunilha"
                rows={3}
                disabled={semEstabelecimentos}
              />
            </div>

            <div>
              <label className="adm-rotulo" htmlFor="rec-custo">Custo em pontos</label>
              <input
                id="rec-custo"
                className="adm-campo"
                type="number"
                min={1}
                value={form.custoPontos}
                onChange={(e) => setForm({ ...form, custoPontos: e.target.value })}
                placeholder="Ex.: 1000"
                required
                disabled={semEstabelecimentos}
              />
            </div>

            <div>
              <label className="adm-rotulo">Foto da recompensa</label>
              <label className="rec-foto-escolher">
                <span className="rec-foto-previa">
                  {previa ? (
                    <img src={previa} alt="" />
                  ) : (
                    <Icone d={IC.imagem} size={18} />
                  )}
                </span>
                <span className="rec-foto-texto">
                  <strong>{foto ? foto.name : "Escolher imagem"}</strong>
                  <small>
                    {foto ? "Clique para trocar" : "Opcional — sem foto, usa a do estabelecimento"}
                  </small>
                </span>
                <input
                  type="file"
                  accept="image/*"
                  hidden
                  disabled={semEstabelecimentos}
                  onChange={(e) => setFoto(e.target.files?.[0] || null)}
                />
              </label>
            </div>

            <button
              type="submit"
              className="adm-btn adm-btn-principal rec-btn-enviar"
              disabled={salvando || semEstabelecimentos}
            >
              <Icone d={IC.presente} size={13} />
              {salvando ? "Salvando…" : "Cadastrar recompensa"}
            </button>
          </form>
        </section>

        <section className="adm-cartao">
          <div className="adm-cartao-topo">
            <h2 className="adm-cartao-titulo">Recompensas cadastradas</h2>
            {recompensas.length > 0 && (
              <span className="adm-cartao-nota adm-num">{recompensas.length} no total</span>
            )}
          </div>

          {semEstabelecimentos ? (
            <p className="adm-vazio">Cadastre uma loja para ver as recompensas.</p>
          ) : recompensas.length === 0 ? (
            <p className="adm-vazio">Nenhuma recompensa para este estabelecimento.</p>
          ) : (
            <ul className="rec-lista">
              {recompensas.map((rec) => {
                const fotoUrl = urlFoto(rec);
                const propria = Boolean(rec.fotoPath);
                return (
                  <li key={rec.id} className="rec-item">
                    <span className="rec-item-foto">
                      {fotoUrl ? (
                        <img src={fotoUrl} alt="" />
                      ) : (
                        <Icone d={IC.presente} size={18} />
                      )}
                    </span>

                    <span className="rec-item-info">
                      <strong className="rec-item-nome">{rec.nome}</strong>
                      <small className="rec-item-desc">{rec.descricao || "Sem descrição"}</small>
                      {!propria && fotoUrl && (
                        <small className="rec-item-heranca">usando a foto do estabelecimento</small>
                      )}
                    </span>

                    <span className="rec-item-custo adm-num">
                      {rec.custoPontos?.toLocaleString("pt-BR")}
                      <small>pts</small>
                    </span>

                    <span className="rec-item-acoes">
                      <button
                        type="button"
                        className="adm-btn"
                        onClick={() => pedirTrocaFoto(rec.id)}
                        disabled={trocandoFoto === rec.id}
                      >
                        <Icone d={IC.imagem} size={13} />
                        {trocandoFoto === rec.id ? "Enviando…" : propria ? "Trocar" : "Definir foto"}
                      </button>
                      <button
                        type="button"
                        className="adm-btn adm-btn-cor"
                        style={{ "--st": "var(--vermelho)" }}
                        onClick={() => setExcluindo(rec)}
                        title="Excluir recompensa"
                      >
                        <Icone d={IC.lixeira} size={13} />
                      </button>
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </div>

      {/* Um input só, reaproveitado por qualquer card que peça troca de foto. */}
      <input
        ref={inputTroca}
        type="file"
        accept="image/*"
        hidden
        onChange={handleTrocaFoto}
      />

      {excluindo && (
        <div
          className="adm-modal-fundo"
          onMouseDown={(e) => e.target === e.currentTarget && setExcluindo(null)}
        >
          <div className="adm-modal">
            <div className="adm-modal-topo">
              <h2 className="adm-cartao-titulo">Excluir recompensa</h2>
              <button
                type="button"
                className="adm-modal-fechar"
                onClick={() => setExcluindo(null)}
              >
                <Icone d={IC.x} size={14} />
              </button>
            </div>
            <p className="adm-modal-texto">
              “{excluindo.nome}” sai do mercado de pontos e os clientes deixam de
              poder resgatá-la. Não dá para desfazer.
            </p>
            <div className="adm-modal-acoes">
              <button type="button" className="adm-btn" onClick={() => setExcluindo(null)}>
                Cancelar
              </button>
              <button
                type="button"
                className="adm-btn adm-btn-cor"
                style={{ "--st": "var(--vermelho)" }}
                onClick={confirmarExclusao}
              >
                <Icone d={IC.lixeira} size={13} />
                Excluir
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
