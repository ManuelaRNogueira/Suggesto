import React, { useEffect, useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import Icone, { IC } from "./Icones";
import { buscarMetricas, buscarSolicitacoes, iniciais } from "../api/admin";
import "../styles/tokens.css";
import "./AdminShell.css";

const NAV = [
  { para: "/", rotulo: "Início", icone: IC.inicio, fim: true },
  { para: "/sugestoes", rotulo: "Sugestões", icone: IC.chat, badgeChave: "sugestoes" },
  { para: "/estatisticas", rotulo: "Estatísticas", icone: IC.barras },
  { para: "/estabelecimentos", rotulo: "Estabelecimentos", icone: IC.predios },
  { para: "/solicitacoes", rotulo: "Solicitações", icone: IC.sino, badgeChave: "solicitacoes" },
];

export default function AdminShell() {
  const [badges, setBadges] = useState({});
  const [usuario, setUsuario] = useState({ nome: "", email: "" });

  useEffect(() => {
    setUsuario({
      nome: localStorage.getItem("nomeUsuario") || "Administrador",
      email: localStorage.getItem("emailUsuario") || "",
    });
  }, []);

  useEffect(() => {
    let vivo = true;
    buscarMetricas()
      .then((m) => vivo && setBadges((b) => ({ ...b, sugestoes: m.novasSemana ?? null })))
      .catch(() => vivo && setBadges((b) => ({ ...b, sugestoes: null })));
    buscarSolicitacoes()
      .then((lista) => vivo && setBadges((b) => ({ ...b, solicitacoes: lista.length })))
      .catch(() => vivo && setBadges((b) => ({ ...b, solicitacoes: null })));
    return () => {
      vivo = false;
    };
  }, []);

  const sair = () => {
    if (!window.confirm("Encerrar sessão?")) return;
    localStorage.clear();
    window.location.reload();
  };

  return (
    <div className="adm-shell">
      <aside className="adm-lateral">
        <div className="adm-lateral-logo">
          <span className="adm-logo-marca">
            <Icone d={IC.logo} size={17} />
          </span>
          <span className="adm-logo-txt">
            Suggesto
            <small>Painel Admin</small>
          </span>
        </div>

        <nav className="adm-nav">
          <p className="adm-nav-secao">Menu</p>
          {NAV.map((item) => (
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
          ))}

          <p className="adm-nav-secao">Conta</p>
          <NavLink
            to="/perfil"
            className={({ isActive }) => `adm-nav-item${isActive ? " ativo" : ""}`}
          >
            <Icone d={IC.usuarios} size={17} className="adm-nav-icone" />
            Perfil e equipe
          </NavLink>
        </nav>

        <div className="adm-lateral-rodape">
          <div className="adm-usuario">
            <span className="adm-usuario-avatar">{iniciais(usuario.nome)}</span>
            <span className="adm-usuario-info">
              <strong>{usuario.nome}</strong>
              <small>{usuario.email || "Administrador"}</small>
            </span>
            <button
              type="button"
              className="adm-usuario-sair"
              onClick={sair}
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
