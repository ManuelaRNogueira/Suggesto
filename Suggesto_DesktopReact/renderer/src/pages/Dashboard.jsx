import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import ModalEstabelecimento from "./ModalEstabelecimento";
import "./Dashboard.css";

const Icon = ({ d, size = 16 }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.8"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d={d} />
  </svg>
);

const IC = {
  menu: "M4 6h16M4 12h16M4 18h16",
  close: "M18 6L6 18M6 6l12 12",
  buildings: "M3 21h18M3 7l9-4 9 4M4 21V7M20 21V7M9 21V13h6v8",
  chat: "M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z",
  star: "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z",
  trending: "M23 6l-9.5 9.5-5-5L1 18",
  pin: "M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z M12 10a1 1 0 100-2 1 1 0 000 2z",
  plus: "M12 5v14M5 12h14",
  trash: "M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6",
  arrow: "M5 12h14M12 5l7 7-7 7",
  user: "M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2 M12 11a4 4 0 100-8 4 4 0 000 8z",
  logo: "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5",
  chevron: "M9 18l6-6-6-6",
};

const inicial = (nome = "") => nome.trim().charAt(0).toUpperCase() || "U";

export default function Dashboard() {
  const [usuario, setUsuario] = useState({ nome: "Carregando", email: "" });
  const [estabelecimentos, setEstab] = useState([]);
  const [sidebarFechada, setSidebar] = useState(false);
  const [modalAberto, setModal] = useState(false);
  const [deletando, setDeletando] = useState(null);
  const [metricas, setMetricas] = useState({
    totalSugestoes: 0,
    mediaGeral: "0.0",
    emAlta: "—",
  });

  useEffect(() => {
    const nome = localStorage.getItem("nomeUsuario") || "Usuário";
    const email = localStorage.getItem("emailUsuario") || "";
    setUsuario({ nome, email });
  }, []);

  useEffect(() => {
    const idGerente = localStorage.getItem("idUsuario");
    if (!idGerente) return;

    (async () => {
      try {
        const rEstab = await fetch(
          `http://localhost:8080/api/estabelecimentos/gerente/${idGerente}`,
        );
        if (!rEstab.ok) return;

        const estabs = await rEstab.json();
        setEstab(estabs);

        if (estabs.length === 0) return;

        let totalSug = 0;
        let somaNotaGeral = 0;
        let locaisAvaliados = [];

        const buscas = estabs.map((e) =>
          fetch(
            `http://localhost:8080/api/avaliacoes/estabelecimento/${e.idEstabelecimento}`,
          )
            .then((res) => (res.ok ? res.json() : []))
            .then((avaliacoes) => {
              if (avaliacoes.length > 0) {
                totalSug += avaliacoes.length;

                const somaLocal = avaliacoes.reduce(
                  (acc, av) => acc + av.nota,
                  0,
                );
                somaNotaGeral += somaLocal;

                locaisAvaliados.push({
                  nome: e.nome,
                  media: somaLocal / avaliacoes.length,
                  qtd: avaliacoes.length,
                });
              }
            })
            .catch(() => {}),
        );

        await Promise.all(buscas);

        const mediaFinal =
          totalSug > 0 ? (somaNotaGeral / totalSug).toFixed(1) : "0.0";

        let emAltaFinal = estabs[0].nome;
        if (locaisAvaliados.length > 0) {
          locaisAvaliados.sort((a, b) => b.media - a.media || b.qtd - a.qtd);
          emAltaFinal = locaisAvaliados[0].nome;
        }

        setMetricas({
          totalSugestoes: totalSug,
          mediaGeral: mediaFinal,
          emAlta: emAltaFinal,
        });
      } catch (e) {
        console.error("Erro ao buscar dados do dashboard:", e);
      }
    })();
  }, []);

  const handleDeletar = async (id) => {
    if (!window.confirm("Tem certeza que deseja apagar este estabelecimento?"))
      return;
    setDeletando(id);
    try {
      const r = await fetch(
        `http://localhost:8080/api/estabelecimentos/${id}`,
        { method: "DELETE" },
      );
      if (r.ok) {
        setEstab((prev) => prev.filter((e) => e.idEstabelecimento !== id));
      } else {
        alert("Erro ao excluir.");
      }
    } catch {
      alert("Erro de comunicação.");
    } finally {
      setDeletando(null);
    }
  };

  const totalEstab = estabelecimentos.length;
  const emAlta = estabelecimentos[0]?.nome ?? "—";
  const horaAtual = new Date().getHours();
  const saudacao =
    horaAtual < 12 ? "Bom dia" : horaAtual < 18 ? "Boa tarde" : "Boa noite";
  const primeiroNome = usuario.nome.split(" ")[0];

  return (
    <div className="dashboard-wrapper">
      {/* ── Glows decorativos ──────────────────────────────────────────────── */}
      <div className="dash-glow-1" />
      <div className="dash-glow-2" />

      {/* ════════════════════════════════════════════════════════════════════
          SIDEBAR
      ════════════════════════════════════════════════════════════════════ */}
      <aside className={`sidebar ${sidebarFechada ? "fechada" : ""}`}>
        {/* Topo: logo + toggle */}
        <div className="side-top">
          <div className="logo-area">
            <div className="logo-icon">
              <Icon d={IC.logo} size={18} />
            </div>
            {!sidebarFechada && (
              <div>
                <p className="logo-name">Suggesto</p>
                <p className="logo-sub">Administração</p>
              </div>
            )}
          </div>
          <button
            className="toggle-btn"
            onClick={() => setSidebar(!sidebarFechada)}
          >
            <Icon d={sidebarFechada ? IC.chevron : IC.close} size={14} />
          </button>
        </div>

        {/* Separador */}
        <div className="side-divider" />

        {!sidebarFechada && (
          <Link to="/recompensas" className="side-item side-item-destaque">
            <div
              className="side-avatar"
              style={{ background: "rgba(124,58,237,0.25)" }}
            >
              <Icon d={IC.star} size={14} />
            </div>
            <div>
              <p className="side-item-nome">Minhas Recompensas</p>
              <p className="side-item-cat">Mercado de pontos</p>
            </div>
          </Link>
        )}

        <div className="side-divider" />

        {/* Rótulo seção */}
        {!sidebarFechada && <p className="side-section">ESTABELECIMENTOS</p>}

        {/* Lista */}
        <div className="side-list">
          {estabelecimentos.length === 0
            ? !sidebarFechada && <p className="side-empty">Nenhum cadastrado</p>
            : estabelecimentos.map((e) => (
                <Link
                  key={`side-${e.idEstabelecimento}`}
                  to={`/estabelecimento/${e.idEstabelecimento}`}
                  className="side-item"
                >
                  <div className="side-avatar">
                    {e.nome.charAt(0).toUpperCase()}
                  </div>
                  {!sidebarFechada && (
                    <div style={{ overflow: "hidden" }}>
                      <p className="side-item-name">{e.nome}</p>
                      <p className="side-item-cat">{e.categoria}</p>
                    </div>
                  )}
                </Link>
              ))}
        </div>

        {/* Perfil bottom */}
        <div className="side-bottom">
          <div className="side-avatar-lg">{inicial(usuario.nome)}</div>
          {!sidebarFechada && (
            <div style={{ overflow: "hidden", flex: 1 }}>
              <p className="side-user-name">{usuario.nome}</p>
              <p className="side-user-email">{usuario.email}</p>
            </div>
          )}
        </div>
      </aside>

      {/* ════════════════════════════════════════════════════════════════════
          CONTEÚDO PRINCIPAL
      ════════════════════════════════════════════════════════════════════ */}
      <main className={`main-content ${sidebarFechada ? "fechada" : ""}`}>
        {/* ── Cabeçalho de boas-vindas ─────────────────────────────────── */}
        <header className="dash-header">
          <div>
            <p className="saudacao">
              {saudacao}, <span className="saudacao-nome">{primeiroNome}</span>
            </p>
            <p className="header-sub">
              Aqui está o panorama dos seus estabelecimentos
            </p>
          </div>
          <button className="btn-novo" onClick={() => setModal(true)}>
            <Icon d={IC.plus} size={15} />
            Novo estabelecimento
          </button>
        </header>

        {/* ── Cards de métricas ────────────────────────────────────────── */}
        <div className="metric-grid">
          <MetricCard
            icon={IC.buildings}
            label="Estabelecimentos"
            value={totalEstab}
            cor="#a78bfa"
          />
          <MetricCard
            icon={IC.chat}
            label="Total de sugestões"
            value={metricas.totalSugestoes}
            cor="#4ade80"
          />
          <MetricCard
            icon={IC.star}
            label="Avaliação média"
            value={metricas.mediaGeral}
            suffix="/ 5"
            cor="#fbbf24"
          />
          <MetricCard
            icon={IC.trending}
            label="Em alta agora"
            value={metricas.emAlta}
            isText
            cor="#f472b6"
          />
        </div>
        {/* ── Título da seção ─────────────────────────────────────────── */}
        <div className="sec-header">
          <h2 className="sec-title">Seus estabelecimentos</h2>
          <span className="sec-count">
            {totalEstab} cadastrado{totalEstab !== 1 ? "s" : ""}
          </span>
        </div>

        {/* ── Grade de estabelecimentos ────────────────────────────────── */}
        <div className="estab-grid">
          {/* Card de adicionar */}
          <button className="card-add" onClick={() => setModal(true)}>
            <div className="card-add-icon">
              <Icon d={IC.plus} size={22} />
            </div>
            <p className="card-add-title">Adicionar novo</p>
            <p className="card-add-sub">Cadastrar estabelecimento</p>
          </button>

          {/* Cards de estabelecimentos */}
          {estabelecimentos.map((e, idx) => (
            <CardEstab
              key={`main-${e.idEstabelecimento}`}
              estab={e}
              idx={idx}
              deletando={deletando === e.idEstabelecimento}
              onDeletar={handleDeletar}
            />
          ))}
        </div>
      </main>

      {/* ── Modal ────────────────────────────────────────────────────────── */}
      {modalAberto && (
        <ModalEstabelecimento
          fecharModal={() => setModal(false)}
          aoSalvar={(novo) => setEstab((prev) => [...prev, novo])}
        />
      )}
    </div>
  );
}

// ─── SUB-COMPONENTE: CARD MÉTRICA ─────────────────────────────────────────────
function MetricCard({ icon, label, value, suffix, cor, isText }) {
  return (
    <div className="metric-card">
      <div
        className="metric-icon"
        style={{ background: `${cor}18`, color: cor }}
      >
        <Icon d={icon} size={18} />
      </div>
      <p className="metric-label">{label}</p>
      <div className="metric-val-row">
        <span
          className="metric-val"
          style={{ fontSize: isText ? "1.2rem" : "2rem", color: cor }}
        >
          {value}
        </span>
        {suffix && <span className="metric-suffix">{suffix}</span>}
      </div>
      <div className="metric-line" style={{ background: cor }} />
    </div>
  );
}

// ─── SUB-COMPONENTE: CARD ESTABELECIMENTO ────────────────────────────────────
const CORES_ACENTO = [
  "#a78bfa",
  "#4ade80",
  "#fbbf24",
  "#f472b6",
  "#38bdf8",
  "#fb923c",
];

function CardEstab({ estab, idx, deletando, onDeletar }) {
  const cor = CORES_ACENTO[idx % CORES_ACENTO.length];

  // 1. Cria a URL da imagem usando a mesma lógica do seu Web App
  const imagemURL = estab.fotoPath
    ? `http://localhost:8080/uploads/${estab.fotoPath}`
    : null;

  return (
    <div className="card-estab">
      {/* Faixa colorida topo */}
      <div className="card-faixa" style={{ background: cor }} />

      {/* 2. Foto com lógica condicional */}
      <div
        className="card-foto"
        style={{
          background: imagemURL
            ? `url('${imagemURL}') center/cover no-repeat`
            : `${cor}12`,
        }}
      >
        {/* Só renderiza o ícone de prédio e o brilho se NÃO tiver imagem */}
        {!imagemURL && (
          <>
            <Icon d={IC.buildings} size={32} />
            <div
              className="card-foto-glow"
              style={{
                background: `radial-gradient(circle, ${cor}22 0%, transparent 70%)`,
              }}
            />
          </>
        )}
      </div>

      {/* Corpo */}
      <div className="card-body">
        <div className="card-top-row">
          <span
            className="card-badge"
            style={{ background: `${cor}18`, color: cor }}
          >
            {estab.categoria}
          </span>
          <button
            className="card-trash"
            onClick={() => onDeletar(estab.idEstabelecimento)}
            disabled={deletando}
            title="Excluir"
          >
            {deletando ? "…" : <Icon d={IC.trash} size={14} />}
          </button>
        </div>

        <h3 className="card-nome">{estab.nome}</h3>

        <p className="card-end">
          <span style={{ color: cor, marginRight: 5 }}>
            <Icon d={IC.pin} size={13} />
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
          Ver detalhes <Icon d={IC.arrow} size={14} />
        </Link>
      </div>
    </div>
  );
}
