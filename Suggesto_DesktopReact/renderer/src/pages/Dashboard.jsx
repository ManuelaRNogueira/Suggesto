import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import ModalEstabelecimento from "./ModalEstabelecimento";
import { Topo } from "../components/AdminShell";
import Icone, { IC } from "../components/Icones";
import { API_BASE, idGerente, urlFoto } from "../api/admin";
import { useAviso } from "../components/Aviso";
import "./Dashboard.css";

export default function Dashboard() {
  const avisar = useAviso();
  const [estabelecimentos, setEstab] = useState([]);
  const [modalAberto, setModal] = useState(false);
  const [deletando, setDeletando] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState(null);

  useEffect(() => {
    const gerente = idGerente();
    if (!gerente) {
      setCarregando(false);
      return;
    }

    let vivo = true;
    (async () => {
      try {
        const resposta = await fetch(`${API_BASE}/estabelecimentos/gerente/${gerente}`);
        if (!resposta.ok) throw new Error(`Erro ${resposta.status}`);
        const lista = await resposta.json();
        if (vivo) setEstab(lista || []);
      } catch (e) {
        if (vivo) setErro(e.message);
      } finally {
        if (vivo) setCarregando(false);
      }
    })();

    return () => {
      vivo = false;
    };
  }, []);

  const handleDeletar = async (id) => {
    if (!window.confirm("Tem certeza que deseja apagar este estabelecimento?")) return;
    setDeletando(id);
    try {
      const r = await fetch(`${API_BASE}/estabelecimentos/${id}`, { method: "DELETE" });
      if (r.ok) {
        setEstab((prev) => prev.filter((e) => e.idEstabelecimento !== id));
      } else {
        avisar("Erro ao excluir.");
      }
    } catch {
      avisar("Erro de comunicação.");
    } finally {
      setDeletando(null);
    }
  };

  const total = estabelecimentos.length;

  return (
    <>
      <Topo
        titulo="Estabelecimentos"
        sub={
          carregando
            ? "Carregando…"
            : `${total} ${total === 1 ? "local cadastrado" : "locais cadastrados"}`
        }
      >
        <button
          type="button"
          className="adm-btn adm-btn-principal"
          onClick={() => setModal(true)}
        >
          <Icone d={IC.predios} size={14} />
          Novo estabelecimento
        </button>
      </Topo>

      {erro && <div className="adm-erro">Não foi possível carregar: {erro}</div>}

      <div className="estab-grid">
        <button type="button" className="card-add" onClick={() => setModal(true)}>
          <span className="card-add-icon">
            <Icone d={IC.predios} size={20} />
          </span>
          <span className="card-add-title">Adicionar novo</span>
          <span className="card-add-sub">Cadastrar estabelecimento</span>
        </button>

        {estabelecimentos.map((e, idx) => (
          <CardEstab
            key={e.idEstabelecimento}
            estab={e}
            idx={idx}
            deletando={deletando === e.idEstabelecimento}
            onDeletar={handleDeletar}
          />
        ))}
      </div>

      {modalAberto && (
        <ModalEstabelecimento
          fecharModal={() => setModal(false)}
          aoSalvar={(novo) => setEstab((prev) => [...prev, novo])}
        />
      )}
    </>
  );
}

// Acentos rotativos: cada card recebe uma cor da paleta do projeto, para a
// grade não virar um bloco monocromático.
const CORES_ACENTO = ["#6366f1", "#818cf8", "#60a5fa", "#22c55e", "#f59e0b", "#eab308"];

function CardEstab({ estab, idx, deletando, onDeletar }) {
  const cor = CORES_ACENTO[idx % CORES_ACENTO.length];

  const imagemURL = urlFoto(estab.fotoPath);

  return (
    <article className="card-estab">
      <div className="card-faixa" style={{ background: cor }} />

      <div
        className="card-foto"
        style={{
          background: imagemURL
            ? `url('${imagemURL}') center/cover no-repeat`
            : `${cor}10`,
        }}
      >
        {!imagemURL && <Icone d={IC.predios} size={28} />}
      </div>

      <div className="card-body">
        <div className="card-top-row">
          <span className="card-badge" style={{ background: `${cor}18`, color: cor }}>
            {estab.categoria}
          </span>
          <button
            type="button"
            className="card-trash"
            onClick={() => onDeletar(estab.idEstabelecimento)}
            disabled={deletando}
            title="Excluir"
          >
            {deletando ? "…" : <Icone d={IC.x} size={13} />}
          </button>
        </div>

        <h3 className="card-nome">{estab.nome}</h3>

        <p className="card-end">
          <span style={{ color: cor, display: "flex" }}>
            <Icone d={IC.local} size={13} />
          </span>
          {estab.rua && estab.numero
            ? `${estab.rua}, ${estab.numero}${estab.bairro ? ` - ${estab.bairro}` : ""} (${estab.cidade}/${estab.estado})`
            : "Endereço não informado"}
        </p>

        <Link
          to={`/estabelecimento/${estab.idEstabelecimento}`}
          className="card-link"
          style={{ color: cor }}
        >
          Ver detalhes <Icone d={IC.seta} size={14} />
        </Link>
      </div>
    </article>
  );
}
