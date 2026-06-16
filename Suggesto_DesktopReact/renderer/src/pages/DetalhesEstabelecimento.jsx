import React, { useState, useEffect, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import './DetalhesEstabelecimento.css';

// ─── CONFIGURAÇÃO DE FILTROS ──────────────────────────────────────────────────
const SENTIMENTOS = [
  { key: 'todos',  label: 'Todos'  },
  { key: 'bom',    label: 'Boas'   },
  { key: 'médio',  label: 'Médias' },
  { key: 'ruim',   label: 'Ruins'  },
];

const CATEGORIAS = [
  { key: 'todos',       label: 'Todas as categorias' },
  { key: 'sugestão',    label: 'Sugestão'    },
  { key: 'crítica',     label: 'Crítica'     },
  { key: 'qualidade',   label: 'Qualidade'   },
  { key: 'atendimento', label: 'Atendimento' },
  { key: 'preço',       label: 'Preço'       },
  { key: 'ambiente',    label: 'Ambiente'    },
];

// ─── HELPERS ──────────────────────────────────────────────────────────────────
const SENT_CONFIG = {
  bom:   { cor: '#4ade80', corFundo: 'rgba(74,222,128,0.12)', label: 'Boa',   icone: '↑' },
  médio: { cor: '#fbbf24', corFundo: 'rgba(251,191,36,0.12)',  label: 'Média', icone: '→' },
  ruim:  { cor: '#f87171', corFundo: 'rgba(248,113,113,0.12)', label: 'Ruim',  icone: '↓' },
};

function formatarData(dataStr) {
  const d = new Date(dataStr + 'T00:00:00');
  if (isNaN(d)) return dataStr; 
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
}

// ─── COMPONENTE PRINCIPAL ─────────────────────────────────────────────────────
function DetalhesEstabelecimento() {
  const { id } = useParams();
  const fileInputRef = useRef(null); // Ref para o input de arquivo escondido
  const [estab, setEstab]               = useState(null);
  const [mediaGeral, setMediaGeral]     = useState(0);
  const [carregando, setCarregando]     = useState(true);
  const [sugestoes, setSugestoes]       = useState([]);
  const [filtroSentimento, setFiltroS]  = useState('todos');
  const [filtroCategoria,  setFiltroC]  = useState('todos');
  const [enviandoFoto, setEnviandoFoto] = useState(false);

  const buscarDados = async () => {
    try {
      // 1. Busca os dados do estabelecimento
      const resEstab = await fetch(`http://localhost:8080/api/estabelecimentos/${id}`);
      if (resEstab.ok) {
          setEstab(await resEstab.json());
      }

      // 2. Busca as avaliações reais do banco
      const resAvaliacoes = await fetch(`http://localhost:8080/api/avaliacoes/estabelecimento/${id}`);
      if (resAvaliacoes.ok) {
          const avaliacoesDoBanco = await resAvaliacoes.json();
          
          let somaNotas = 0;

          // 3. A TRADUÇÃO (Sentimento da Categoria + Nota)
          const sugestoesFormatadas = avaliacoesDoBanco.map(av => {
              somaNotas += av.nota;

              let sent = 'ruim';
              if (av.nota >= 4) sent = 'bom';
              else if (av.nota === 3) sent = 'médio';

              return {
                  id: av.idAvaliacao,
                  texto: av.comentario,
                  nota: av.nota,
                  sentimento: sent,
                  categoria: av.categoria?.nomeCategoria?.toLowerCase() || 'sugestão',
                  autor: av.usuario?.nome || 'Cliente Verificado',
                  status: (av.status || 'analise').toLowerCase(),
                  data: av.dataAvaliacao
                    ? av.dataAvaliacao.split('T')[0]
                    : new Date().toISOString().split('T')[0]
              };
          });

          // 4. Calcula a Média Geral do Estabelecimento
          const media = avaliacoesDoBanco.length > 0 
              ? (somaNotas / avaliacoesDoBanco.length).toFixed(1) 
              : 0;
          
          setMediaGeral(media);
          setSugestoes(sugestoesFormatadas);
      }
    } catch (e) {
      console.error('Erro ao buscar dados:', e);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    buscarDados();
  }, [id]);

  // Função disparada ao selecionar uma nova foto
  const lidarComTrocaFoto = async (e) => {
    const arquivo = e.target.files[0];
    if (!arquivo) return;

    const formData = new FormData();
    formData.append('foto', arquivo);

    setEnviandoFoto(true);
    try {
      const res = await fetch(`http://localhost:8080/api/estabelecimentos/${id}/foto`, {
        method: 'POST', // Bate certinho com o @PostMapping("/{id}/foto") do Java
        body: formData,
      });

      if (res.ok) {
        // Recarrega os dados para atualizar a foto na tela na mesma hora
        await buscarDados();
      } else {
        alert('Erro ao enviar a nova foto.');
      }
    } catch (error) {
      console.error('Erro no upload:', error);
      alert('Erro de conexão ao enviar foto.');
    } finally {
      setEnviandoFoto(false);
    }
  };

  const atualizarStatus = async (idAvaliacao, status) => {
    try {
      const r = await fetch(`http://localhost:8080/api/avaliacoes/${idAvaliacao}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      if (!r.ok) {
        const err = await r.json();
        throw new Error(err.message || 'Erro ao atualizar status.');
      }
      setSugestoes((prev) =>
        prev.map((s) =>
          s.id === idAvaliacao ? { ...s, status: status.toLowerCase() } : s
        )
      );
    } catch (e) {
      console.error(e);
      alert(e.message || 'Não foi possível atualizar a sugestão.');
    }
  };

  const statusAceito = (status) =>
    ['aceita', 'aceito', 'resolvida', 'resolvido', 'implementado', 'implementada'].includes(
      (status || '').toLowerCase()
    );

  // ── Filtragem ──────────────────────────────────────────────────────────────
  const sugestoesFiltradas = sugestoes.filter((s) => {
    const passaSent = filtroSentimento === 'todos' || s.sentimento === filtroSentimento;
    const passaCat  = filtroCategoria  === 'todos' || s.categoria  === filtroCategoria;
    return passaSent && passaCat;
  });

  // ── Contadores por sentimento ──────────────────────────────────────────────
  const contagem = {
    bom:   sugestoes.filter((s) => s.sentimento === 'bom').length,
    médio: sugestoes.filter((s) => s.sentimento === 'médio').length,
    ruim:  sugestoes.filter((s) => s.sentimento === 'ruim').length,
  };

  if (carregando) {
    return (
      <div className="estado-central">
        <div className="spinner" />
        <p>Carregando dados...</p>
      </div>
    );
  }

  const dados = estab || { nome: 'Estabelecimento não encontrado', endereco: '' };

  return (
    <div className="pagina">
      <div className="glow-1" />
      <div className="glow-2" />

      {/* Input de arquivo invisível controlado pelo clique no botão de lápis */}
      <input 
        type="file" 
        ref={fileInputRef} 
        style={{ display: 'none' }} 
        accept="image/*"
        onChange={lidarComTrocaFoto}
      />

      {/* ── Cabeçalho ───────────────────────────────────────────────────── */}
      <header className="cabecalho">
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          <Link to="/" className="btn-voltar">
            ← Dashboard
          </Link>
          <Link to={`/estabelecimento/${id}/recompensas`} className="btn-voltar">
            Minhas Recompensas
          </Link>
        </div>

      <div className="cabecalho-container-flex">
          {/* LADO ESQUERDO: TEXTOS */}
          <div className="cabecalho-corpo">
            <span className="badge-categoria">GERAL</span>
            <h1 className="titulo-nome">{dados.nome}</h1>
            <p className="texto-endereco">📍 {dados.rua}, {dados.numero} - {dados.bairro}, {dados.cidade} - {dados.estado}</p>
            
            {mediaGeral > 0 && (
              <div className="media-geral">
                ⭐ {mediaGeral} <span className="media-geral-label">/ 5 Média</span>
              </div>
            )}
          </div>

          {/* LADO DIREITO: FOTO GRANDE EM DESTAQUE */}
          <div className={`cabecalho-bloco-foto ${enviandoFoto ? 'processando' : ''}`}>
            <div className="container-foto-estab">
              {dados.fotoPath ? (
                <img 
                  src={`http://localhost:8080/uploads/${dados.fotoPath}`} 
                  alt={dados.nome} 
                  className="foto-estabelecimento"
                />
              ) : (
                <div className="foto-estabelecimento-placeholder">
                  {dados.nome.charAt(0).toUpperCase()}
                </div>
              )}
              
              <button 
                className="btn-editar-foto" 
                title="Alterar foto do estabelecimento"
                onClick={() => fileInputRef.current.click()}
                disabled={enviandoFoto}
              >
                {enviandoFoto ? '...' : '✏️ Editar Foto'}
              </button>
            </div>
          </div>
        </div>

        {/* ── Mini-stats ──────────────────────────────────────────────── */}
        <div className="mini-stats">
          <div className="stat-item">
            <span className="stat-num">{sugestoes.length}</span>
            <span className="stat-label">Total</span>
          </div>
          <div className="stat-divider" />
          <div className="stat-item">
            <span className="stat-num" style={{ color: '#4ade80' }}>{contagem.bom}</span>
            <span className="stat-label">Boas</span>
          </div>
          <div className="stat-divider" />
          <div className="stat-item">
            <span className="stat-num" style={{ color: '#fbbf24' }}>{contagem.médio}</span>
            <span className="stat-label">Médias</span>
          </div>
          <div className="stat-divider" />
          <div className="stat-item">
            <span className="stat-num" style={{ color: '#f87171' }}>{contagem.ruim}</span>
            <span className="stat-label">Ruins</span>
          </div>
        </div>
      </header>

      {/* ── Barra de filtros ────────────────────────────────────────────── */}
      <div className="barra-filtros">
        <div className="grupo-filtro">
          <span className="filtro-rotulo">AVALIAÇÃO</span>
          <div className="pílulas">
            {SENTIMENTOS.map(({ key, label }) => (
              <button
                key={key}
                className={`pílula ${filtroSentimento === key ? 'ativa' : ''}`}
                style={
                  filtroSentimento === key && key !== 'todos'
                    ? {
                        backgroundColor: SENT_CONFIG[key].corFundo,
                        borderColor:     SENT_CONFIG[key].cor,
                        color:           SENT_CONFIG[key].cor,
                      }
                    : {}
                }
                onClick={() => setFiltroS(key)}
              >
                {key !== 'todos' && (
                  <span
                    className="ponto-sent"
                    style={{ backgroundColor: SENT_CONFIG[key].cor }}
                  />
                )}
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="filtro-separador" />

        <div className="grupo-filtro">
          <span className="filtro-rotulo">CATEGORIA</span>
          <div className="pílulas">
            {CATEGORIAS.map(({ key, label }) => (
              <button
                key={key}
                className={`pílula ${filtroCategoria === key ? 'ativa' : ''}`}
                onClick={() => setFiltroC(key)}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Resultado e contagem ────────────────────────────────────────── */}
      <div className="resultado-header">
        <span className="resultado-contagem">
          {sugestoesFiltradas.length} registro{sugestoesFiltradas.length !== 1 ? 's' : ''} encontrado{sugestoesFiltradas.length !== 1 ? 's' : ''}
        </span>
        <span className="resultado-desc">
          {filtroSentimento !== 'todos' || filtroCategoria !== 'todos'
            ? 'Filtros ativos — clique em "Todos" para limpar'
            : 'Exibindo todas as avaliações'}
        </span>
      </div>

      {/* ── Grade de sugestões ──────────────────────────────────────────── */}
      <main className="grade-sugestoes">
        {sugestoesFiltradas.length === 0 ? (
          <div className="vazio">
            <span className="vazio-icone">⊘</span>
            <p>Nenhuma sugestão encontrada para estes filtros.</p>
            <button
              className="btn-limpar"
              onClick={() => { setFiltroS('todos'); setFiltroC('todos'); }}
            >
              Limpar filtros
            </button>
          </div>
        ) : (
          sugestoesFiltradas.map((s) => {
            const cfg = SENT_CONFIG[s.sentimento];
            return (
              <article
                key={s.id}
                className="card-sugestao"
                style={{ borderLeftColor: cfg.cor }}
              >
                <div className="card-topo">
                  <span
                    className="tag-sentimento"
                    style={{ backgroundColor: cfg.corFundo, color: cfg.cor }}
                  >
                    {cfg.icone} {cfg.label}
                  </span>
                  <span className="tag-categoria">{s.categoria}</span>
                  
                  <span className="card-data">⭐ {s.nota}/5 • {formatarData(s.data)}</span>
                </div>

                <p className="card-texto">"{s.texto}"</p>

                <div className="card-rodape">
                  <div className="avatar">
                    {s.autor.charAt(0).toUpperCase()}
                  </div>
                  <span className="card-autor">{s.autor}</span>
                  <span className="card-status-tag">{s.status}</span>
                </div>

                {!statusAceito(s.status) && s.status !== 'recusada' && s.status !== 'recusado' && (
                  <div className="card-acoes-admin">
                    <button
                      type="button"
                      className="btn-aceitar"
                      onClick={() => atualizarStatus(s.id, 'ACEITA')}
                    >
                      Aceitar (+500 pts)
                    </button>
                    <button
                      type="button"
                      className="btn-recusar"
                      onClick={() => atualizarStatus(s.id, 'RECUSADA')}
                    >
                      Recusar
                    </button>
                  </div>
                )}
              </article>
            );
          })
        )}
      </main>
    </div>
  );
}

export default DetalhesEstabelecimento;