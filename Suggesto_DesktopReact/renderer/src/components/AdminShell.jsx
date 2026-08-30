import React, { useEffect, useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import Icone, { IC } from "./Icones";
import {
  buscarMeuPlano,
  buscarMetricas,
  buscarSolicitacoes,
  buscarUsuario,
  iniciais,
  possuoAlgumEstabelecimento,
  urlFoto,
} from "../api/admin";
import "../styles/tokens.css";
import "./AdminShell.css";

// `recurso` liga o item ao que o plano do administrador libera (ver planos.html).
// Item bloqueado pelo plano não some — fica visível com o selo "Pro" (ver bloqueadoPorPlano).
const NAV = [
  { para: "/", rotulo: "Início", icone: IC.inicio, fim: true },
  { para: "/sugestoes", rotulo: "Sugestões", icone: IC.chat, badgeChave: "sugestoes" },
  { para: "/estatisticas", rotulo: "Estatísticas", icone: IC.barras, recurso: "permiteRelatorios" },
  { para: "/estabelecimentos", rotulo: "Estabelecimentos", icone: IC.predios },
  { para: "/solicitacoes", rotulo: "Solicitações", icone: IC.sino, badgeChave: "solicitacoes", somentePrincipal: true, equipe: true },
  { para: "/recompensas", rotulo: "Minhas recompensas", icone: IC.presente, recurso: "permiteRecompensas" },
];

// Único plano pago que já libera tudo — é o que vale mostrar como "próximo passo".
const PLANO_SUGERIDO = "Pro";

function bloqueadoPorPlano(item, plano) {
  if (!plano) return false;
  if (item.recurso && plano[item.recurso] === false) return true;
  if (item.equipe && plano.limiteAdmins === 1) return true;
  return false;
}

export default function AdminShell() {
  const [badges, setBadges] = useState({});
  const [usuario, setUsuario] = useState({ nome: "", email: "" });
  const [confirmandoSaida, setConfirmandoSaida] = useState(false);
  // Enquanto o plano não chega, nada é escondido — evita a sidebar "piscar".
  const [plano, setPlano] = useState(null);
  const [avisoPlano, setAvisoPlano] = useState(null);
  // "Sou dona de algo" é por estabelecimento agora, então precisa ser
  // buscado — null enquanto carrega (nada fica escondido até resolver).
  const [souDonoDeAlgo, setSouDonoDeAlgo] = useState(null);

  useEffect(() => {
    setUsuario({
      nome: localStorage.getItem("nomeUsuario") || "Administrador",
      email: localStorage.getItem("emailUsuario") || "",
    });

    // Busca a foto de perfil de verdade — só troca as iniciais se existir.
    const idUsuario = localStorage.getItem("idUsuario");
    if (idUsuario) {
      buscarUsuario(idUsuario)
        .then((dados) => setUsuario((u) => ({ ...u, fotoUrl: dados?.fotoUrl })))
        .catch(() => {});
    }
  }, []);

  useEffect(() => {
    let vivo = true;
    buscarMetricas()
      .then((m) => vivo && setBadges((b) => ({ ...b, sugestoes: m.novasSemana ?? null })))
      .catch(() => vivo && setBadges((b) => ({ ...b, sugestoes: null })));
    buscarMeuPlano()
      .then((p) => vivo && setPlano(p))
      .catch(() => {});
    possuoAlgumEstabelecimento()
      .then((v) => vivo && setSouDonoDeAlgo(v))
      .catch(() => vivo && setSouDonoDeAlgo(false));
    return () => {
      vivo = false;
    };
  }, []);

  useEffect(() => {
    if (!souDonoDeAlgo) return;
    let vivo = true;
    buscarSolicitacoes()
      .then((lista) => vivo && setBadges((b) => ({ ...b, solicitacoes: lista.length })))
      .catch(() => vivo && setBadges((b) => ({ ...b, solicitacoes: null })));
    return () => {
      vivo = false;
    };
  }, [souDonoDeAlgo]);

  const confirmarSair = () => {
    localStorage.clear();
    window.location.reload();
  };

  return (
    <div className="adm-shell">
      <aside className="adm-lateral">
        <div className="adm-lateral-logo">
          <span className="adm-logo-marca">
            <img src="/img/logoBalao.png" alt="Suggesto" style={{ width: 22, height: 22, objectFit: "contain" }} />
          </span>
          <span className="adm-logo-txt">
            Suggesto
            <small>Painel Admin</small>
          </span>
        </div>

        <nav className="adm-nav">
          <p className="adm-nav-secao">Menu</p>
          {NAV.filter((item) => !item.somentePrincipal || souDonoDeAlgo !== false).map((item) => {
            const trancado = bloqueadoPorPlano(item, plano);
            if (trancado) {
              return (
                <button
                  key={item.para}
                  type="button"
                  className="adm-nav-item adm-nav-item-trancado"
                  onClick={() => setAvisoPlano(item.rotulo)}
                >
                  <Icone d={item.icone} size={17} className="adm-nav-icone" />
                  {item.rotulo}
                  <span className="adm-nav-selo">
                    <Icone d={IC.cadeado} size={10} />
                    {PLANO_SUGERIDO}
                  </span>
                </button>
              );
            }
            return (
              <NavLink
                key={item.para}
                to={item.para}
                end={item.fim}
                className={({ isActive }) =>
                  `adm-nav-item${isActive ? " ativo" : ""}`
                }
              >
                <Icone d={item.icone} size={17} className="adm-nav-icone" />
                {item.rotulo}
                {item.badgeChave && badges[item.badgeChave] > 0 && (
                  <span className="adm-nav-badge adm-num">{badges[item.badgeChave]}</span>
                )}
              </NavLink>
            );
          })}

          <p className="adm-nav-secao">Conta</p>
          <NavLink
            to="/perfil"
            className={({ isActive }) => `adm-nav-item${isActive ? " ativo" : ""}`}
          >
            <Icone d={IC.usuarios} size={17} className="adm-nav-icone" />
            Perfil e equipe
          </NavLink>
          {souDonoDeAlgo !== false && (
            <NavLink
              to="/plano"
              className={({ isActive }) => `adm-nav-item${isActive ? " ativo" : ""}`}
            >
              <Icone d={IC.estrela} size={17} className="adm-nav-icone" />
              Plano
              {plano?.nome && <span className="adm-nav-badge">{plano.nome}</span>}
            </NavLink>
          )}
        </nav>

        <div className="adm-lateral-rodape">
          <div className="adm-usuario">
            <span
              className="adm-usuario-avatar"
              style={
                urlFoto(usuario.fotoUrl)
                  ? { background: "transparent", boxShadow: "none", border: "none" }
                  : undefined
              }
            >
              {urlFoto(usuario.fotoUrl) ? (
                <img
                  src={urlFoto(usuario.fotoUrl)}
                  alt=""
                  style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "50%", display: "block" }}
                />
              ) : (
                iniciais(usuario.nome)
              )}
            </span>
            <span className="adm-usuario-info">
              <strong>{usuario.nome}</strong>
              <small>{usuario.email || "Administrador"}</small>
            </span>
            <button
              type="button"
              className="adm-usuario-sair"
              onClick={() => setConfirmandoSaida(true)}
              title="Sair"
            >
              <Icone d={IC.sair} size={13} />
            </button>
          </div>
        </div>
      </aside>

      <main className="adm-conteudo">
        <Outlet />
      </main>

      {confirmandoSaida && (
        <div
          className="adm-modal-fundo"
          onMouseDown={(e) => e.target === e.currentTarget && setConfirmandoSaida(false)}
        >
          <div className="adm-modal">
            <div className="adm-modal-topo">
              <h2 className="adm-cartao-titulo">Encerrar sessão</h2>
              <button
                type="button"
                className="adm-modal-fechar"
                onClick={() => setConfirmandoSaida(false)}
              >
                <Icone d={IC.x} size={14} />
              </button>
            </div>
            <p className="adm-modal-texto">
              Tem certeza que deseja sair do painel administrativo?
            </p>
            <div className="adm-modal-acoes">
              <button
                type="button"
                className="adm-btn"
                onClick={() => setConfirmandoSaida(false)}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="adm-btn adm-btn-cor"
                style={{ "--st": "var(--vermelho)" }}
                onClick={confirmarSair}
              >
                <Icone d={IC.sair} size={13} />
                Sair
              </button>
            </div>
          </div>
        </div>
      )}

      {avisoPlano && (
        <div
          className="adm-modal-fundo"
          onMouseDown={(e) => e.target === e.currentTarget && setAvisoPlano(null)}
        >
          <div className="adm-modal">
            <div className="adm-modal-topo">
              <h2 className="adm-cartao-titulo">Disponível no {PLANO_SUGERIDO}</h2>
              <button
                type="button"
                className="adm-modal-fechar"
                onClick={() => setAvisoPlano(null)}
              >
                <Icone d={IC.x} size={14} />
              </button>
            </div>
            <p className="adm-modal-texto">
              "{avisoPlano}" não está incluído no seu plano atual. Faça upgrade
              para o {PLANO_SUGERIDO} para liberar essa função.
            </p>
            <div className="adm-modal-acoes">
              <button type="button" className="adm-btn" onClick={() => setAvisoPlano(null)}>
                Fechar
              </button>
              <NavLink
                to="/plano"
                className="adm-btn adm-btn-principal"
                onClick={() => setAvisoPlano(null)}
              >
                Ver planos
              </NavLink>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Cabeçalho reaproveitado por todas as telas do painel.
export function Topo({ titulo, sub, children }) {
  return (
    <header className="adm-topo">
      <div>
        <h1 className="adm-topo-titulo">{titulo}</h1>
        {sub && <p className="adm-topo-sub">{sub}</p>}
      </div>
      {children && <div className="adm-topo-acoes">{children}</div>}
    </header>
  );
}
