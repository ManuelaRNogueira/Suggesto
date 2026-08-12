import React, { createContext, useCallback, useContext, useEffect, useState } from "react";
import Icone, { IC } from "./Icones";
import "./Aviso.css";

const AvisoContexto = createContext(() => {});

// Substitui o alert() nativo, que abria uma caixa do Windows no meio de um painel
// escuro. Fica no topo da árvore para qualquer tela avisar sem controlar estado
// próprio: basta `const avisar = useAviso()` e chamar `avisar("mensagem")`.
export function AvisoProvider({ children }) {
  const [aviso, setAviso] = useState(null);

  const avisar = useCallback((mensagem, titulo = "Aviso") => {
    setAviso({ mensagem: String(mensagem ?? ""), titulo });
  }, []);

  const fechar = useCallback(() => setAviso(null), []);

  useEffect(() => {
    if (!aviso) return undefined;
    const aoTeclar = (evento) => {
      if (evento.key === "Escape") fechar();
    };
    window.addEventListener("keydown", aoTeclar);
    return () => window.removeEventListener("keydown", aoTeclar);
  }, [aviso, fechar]);

  return (
    <AvisoContexto.Provider value={avisar}>
      {children}

      {aviso && (
        <div className="aviso-overlay" onClick={fechar} role="presentation">
          <div
            className="aviso-painel"
            role="alertdialog"
            aria-modal="true"
            aria-label={aviso.titulo}
            onClick={(evento) => evento.stopPropagation()}
          >
            <span className="aviso-icone">
              <Icone d={IC.alerta} size={20} />
            </span>

            <h3 className="aviso-titulo">{aviso.titulo}</h3>
            <p className="aviso-msg">{aviso.mensagem}</p>

            <button type="button" className="aviso-botao" onClick={fechar} autoFocus>
              Entendi
            </button>
          </div>
        </div>
      )}
    </AvisoContexto.Provider>
  );
}

export function useAviso() {
  return useContext(AvisoContexto);
}
