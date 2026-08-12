import React, { useEffect, useState } from "react";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import { EstadoCarregando, EstadoErro } from "./Inicio";
import {
  API_BASE,
  aceitarSolicitacao,
  buscarSolicitacoes,
  formatarData,
  idGerente,
  iniciais,
  recusarSolicitacao,
} from "../../api/admin";
import { useAviso } from "../../components/Aviso";
import "./Solicitacoes.css";

export default function Solicitacoes() {
  const avisar = useAviso();
  const [estabelecimentos, setEstabelecimentos] = useState([]);
  const [solicitacoes, setSolicitacoes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState(null);
  const [respondendo, setRespondendo] = useState(null);
  const [copiado, setCopiado] = useState(null);

  useEffect(() => {
    const gerente = idGerente();
    if (!gerente) {
      setCarregando(false);
      return;
    }

    let vivo = true;
    Promise.all([
      fetch(`${API_BASE}/estabelecimentos/gerente/${gerente}`).then((r) => r.json()),
      buscarSolicitacoes(),
    ])
      .then(([estabs, pedidos]) => {
        if (!vivo) return;
        setEstabelecimentos(estabs || []);
        setSolicitacoes(pedidos || []);
      })
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));

    return () => {
      vivo = false;
    };
  }, []);

  const copiarCodigo = (codigo) => {
    navigator.clipboard.writeText(codigo);
    setCopiado(codigo);
    setTimeout(() => setCopiado(null), 2000);
  };

  const responder = async (id, aceitar) => {
    setRespondendo(id);
    try {
      if (aceitar) {
        await aceitarSolicitacao(id);
      } else {
        await recusarSolicitacao(id);
      }
      setSolicitacoes((prev) => prev.filter((s) => s.id !== id));
    } catch (e) {
      avisar(e.message || "Erro ao responder a solicitação.");
    } finally {
      setRespondendo(null);
    }
  };

  if (carregando) return <EstadoCarregando />;
  if (erro) return <EstadoErro mensagem={erro} />;

  return (
    <>
      <Topo
        titulo="Solicitações"
        sub={
          solicitacoes.length === 0
            ? "Nenhum pedido pendente"
            : `${solicitacoes.length} ${solicitacoes.length === 1 ? "pedido pendente" : "pedidos pendentes"}`
        }
      />

      <div className="sol-secoes">
      <section className="adm-cartao">
        <div className="adm-cartao-topo">
          <h2 className="adm-cartao-titulo">Código da equipe</h2>
        </div>
        <p className="sol-nota">
          Compartilhe o código do seu estabelecimento com quem você quer convidar. A pessoa entra com esse código no site e o pedido aparece aqui para você aceitar.
        </p>
        {estabelecimentos.length === 0 ? (
          <p className="adm-vazio">Nenhum estabelecimento cadastrado.</p>
        ) : (
          <ul className="sol-codigos">
            {estabelecimentos.map((e) => (
              <li key={e.idEstabelecimento} className="sol-codigo-item">
                <span className="sol-codigo-nome">{e.nome}</span>
                <span className="sol-codigo-valor adm-num">{e.codigoAcesso}</span>
                <button
                  type="button"
                  className="adm-btn"
                  onClick={() => copiarCodigo(e.codigoAcesso)}
                >
                  <Icone d={copiado === e.codigoAcesso ? IC.check : IC.copiar} size={13} />
                  {copiado === e.codigoAcesso ? "Copiado" : "Copiar"}
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="adm-cartao">
        <div className="adm-cartao-topo">
          <h2 className="adm-cartao-titulo">Pedidos para entrar na equipe</h2>
          <span className="adm-cartao-nota adm-num">{solicitacoes.length}</span>
        </div>
        {solicitacoes.length === 0 ? (
          <p className="adm-vazio">Nenhuma solicitação pendente.</p>
        ) : (
          <ul className="sol-lista">
            {solicitacoes.map((s) => (
              <li key={s.id} className="sol-item">
                <span className="sol-avatar">{iniciais(s.nomeUsuario)}</span>
                <span className="sol-info">
                  <span className="sol-nome">{s.nomeUsuario}</span>
                  <span className="sol-meta">
                    {s.emailUsuario} · quer entrar em {s.nomeEstabelecimento} · {formatarData(s.dataSolicitacao)}
                  </span>
                </span>
                <span className="sol-acoes">
                  <button
                    type="button"
                    className="adm-btn"
                    disabled={respondendo === s.id}
                    onClick={() => responder(s.id, false)}
                  >
                    <Icone d={IC.x} size={13} />
                    Recusar
                  </button>
                  <button
                    type="button"
                    className="adm-btn adm-btn-principal"
                    disabled={respondendo === s.id}
                    onClick={() => responder(s.id, true)}
                  >
                    <Icone d={IC.check} size={13} />
                    Aceitar
                  </button>
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
      </div>
    </>
  );
}
