import React, { useEffect, useState } from "react";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import CartaoPagamento from "../../components/CartaoPagamento";
import { EstadoCarregando, EstadoErro } from "./Inicio";
import { buscarMeuPlano, listarPlanos, possuoAlgumEstabelecimento, trocarPlano } from "../../api/admin";
import "./Plano.css";

function limite(n, singular, plural) {
  if (n === null || n === undefined) return "Ilimitado";
  return `Até ${n} ${n === 1 ? singular : plural}`;
}

export default function Plano() {
  const [planos, setPlanos] = useState([]);
  const [meuPlano, setMeuPlano] = useState(null);
  const [erro, setErro] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [escolhido, setEscolhido] = useState(null);
  const [trocando, setTrocando] = useState(false);
  const [erroTroca, setErroTroca] = useState(null);
  const [aviso, setAviso] = useState(null);
  // null = ainda não sabemos; "sou dona de algo" agora é por estabelecimento,
  // então precisa ser buscado (não dá mais pra saber só com o localStorage).
  const [principal, setPrincipal] = useState(null);

  useEffect(() => {
    let vivo = true;
    possuoAlgumEstabelecimento()
      .then((v) => vivo && setPrincipal(v))
      .catch(() => vivo && setPrincipal(false));
    return () => {
      vivo = false;
    };
  }, []);

  const carregar = () => {
    let vivo = true;
    setCarregando(true);
    Promise.all([listarPlanos(), buscarMeuPlano()])
      .then(([lista, meu]) => {
        if (!vivo) return;
        setPlanos((lista || []).slice().sort((a, b) => (a.preco ?? 0) - (b.preco ?? 0)));
        setMeuPlano(meu);
        setErro(null);
      })
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));
    return () => {
      vivo = false;
    };
  };

  useEffect(carregar, []);

  useEffect(() => {
    if (!aviso) return;
    const t = setTimeout(() => setAviso(null), 3200);
    return () => clearTimeout(t);
  }, [aviso]);

  const confirmarTroca = async () => {
    if (!escolhido) return;
    setTrocando(true);
    setErroTroca(null);
    try {
      const resumo = await trocarPlano(escolhido.nome);
      setMeuPlano(resumo);
      setEscolhido(null);
      setAviso(`Plano trocado para ${escolhido.nome}.`);
    } catch (e) {
      setErroTroca(e.message || "Não foi possível trocar de plano.");
    } finally {
      setTrocando(false);
    }
  };

  if (carregando) return <EstadoCarregando />;
  if (erro) return <EstadoErro mensagem={erro} />;

  return (
    <>
      <Topo titulo="Plano" sub="Compare os planos e troque quando precisar" />

      {principal === false && (
        <div className="adm-erro" style={{ marginBottom: 20 }}>
          Só quem possui um estabelecimento pode trocar o plano.
        </div>
      )}

      <div className="pln-grade">
        {planos.map((p) => {
          const atual = p.nome === meuPlano?.nome;
          const destaque = p.nome === "Pro";
          return (
            <section
              key={p.id}
              className={`adm-cartao pln-cartao${atual ? " pln-atual" : ""}${destaque ? " pln-destaque" : ""}`}
            >
              {destaque && <span className="pln-badge-popular">Mais popular</span>}

              <div className="pln-topo">
                <h2 className="pln-nome">{p.nome}</h2>
                {atual && <span className="pln-selo">Seu plano atual</span>}
              </div>
              {p.descricao && <p className="pln-descricao">{p.descricao}</p>}

              <p className="pln-preco">
                {p.preco ? (
                  <>
                    <span className="pln-preco-moeda">R$</span>
                    <span className="pln-preco-valor">{p.preco.toFixed(2).replace(".", ",")}</span>
                    <span className="pln-preco-periodo">/mês</span>
                  </>
                ) : (
                  <span className="pln-preco-valor">Grátis</span>
                )}
              </p>

              <button
                type="button"
                className={`adm-btn${atual ? "" : " adm-btn-principal"} pln-btn`}
                disabled={atual || principal === false}
                onClick={() => setEscolhido(p)}
              >
                {atual ? "Plano atual" : `Trocar para o ${p.nome}`}
              </button>

              <div className={`pln-divisor${destaque ? " pln-divisor-roxo" : ""}`}></div>

              <ul className="pln-recursos">
                <li>{limite(p.limiteEstabelecimentos, "estabelecimento", "estabelecimentos")}</li>
                <li>{limite(p.limiteFeedbacksMes, "feedback/mês", "feedbacks/mês")}</li>
                <li>{limite(p.limiteAdmins, "administrador", "administradores")}</li>
                <li className={p.permiteRelatorios === false ? "pln-recurso-sem" : ""}>
                  <Icone d={p.permiteRelatorios === false ? IC.x : IC.check} size={13} />
                  Relatórios e estatísticas
                </li>
                <li className={p.permiteExportacao === false ? "pln-recurso-sem" : ""}>
                  <Icone d={p.permiteExportacao === false ? IC.x : IC.check} size={13} />
                  Exportação de dados
                </li>
                <li className={p.permiteRecompensas === false ? "pln-recurso-sem" : ""}>
                  <Icone d={p.permiteRecompensas === false ? IC.x : IC.check} size={13} />
                  Recompensas
                </li>
              </ul>
            </section>
          );
        })}
      </div>

      {escolhido && (
        <div
          className="adm-modal-fundo"
          onMouseDown={(e) => e.target === e.currentTarget && !trocando && setEscolhido(null)}
        >
          <div className="adm-modal pln-modal-pagamento">
            <div className="adm-modal-topo">
              <h2 className="adm-cartao-titulo">Trocar para o {escolhido.nome}</h2>
              <button
                type="button"
                className="adm-modal-fechar"
                onClick={() => setEscolhido(null)}
                disabled={trocando}
              >
                <Icone d={IC.x} size={14} />
              </button>
            </div>
            <p className="adm-modal-texto">
              O plano do estabelecimento passa a ser {escolhido.nome}
              {escolhido.preco ? ` (R$ ${escolhido.preco.toFixed(2).replace(".", ",")}/mês)` : ""}.
            </p>
            {erroTroca && <div className="adm-erro">{erroTroca}</div>}

            <CartaoPagamento
              onConfirmar={confirmarTroca}
              carregando={trocando}
              textoBotao={`Confirmar assinatura do ${escolhido.nome}`}
            />

            <button
              type="button"
              className="adm-btn pln-btn-cancelar"
              onClick={() => setEscolhido(null)}
              disabled={trocando}
            >
              Cancelar
            </button>
          </div>
        </div>
      )}

      {aviso && <div className="pln-aviso">{aviso}</div>}
    </>
  );
}
