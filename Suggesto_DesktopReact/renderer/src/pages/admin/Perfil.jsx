import React, { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Topo } from "../../components/AdminShell";
import Icone, { IC } from "../../components/Icones";
import { EstadoCarregando, EstadoErro } from "./Inicio";
import {
  atualizarPerfil,
  buscarEstabelecimentos,
  buscarMetricas,
  buscarUsuario,
  buscarUsuarios,
  desativarEstabelecimento,
  idGerente,
  iniciais,
  removerAdministrador,
  urlFoto,
} from "../../api/admin";
import "./Perfil.css";

export default function Perfil() {
  const [usuario, setUsuario] = useState(null);
  const [metricas, setMetricas] = useState(null);
  const [admins, setAdmins] = useState([]);
  const [estabelecimentos, setEstabelecimentos] = useState([]);
  const [erro, setErro] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [editando, setEditando] = useState(false);
  const [aviso, setAviso] = useState(null);
  const [confirmandoDesativacao, setConfirmandoDesativacao] = useState(null);
  const [desativandoId, setDesativandoId] = useState(null);
  const [confirmandoRemocao, setConfirmandoRemocao] = useState(null);
  const [codigoRemocao, setCodigoRemocao] = useState("");
  const [removendoId, setRemovendoId] = useState(null);

  const id = idGerente();
  const meuId = localStorage.getItem("idUsuario");
  const souPrincipal = String(meuId) === String(id);

  useEffect(() => {
    if (!id) {
      setErro("Sessão sem id de usuário. Entre novamente.");
      setCarregando(false);
      return;
    }
    let vivo = true;
    Promise.all([
      buscarUsuario(meuId),
      buscarMetricas(),
      buscarUsuarios(),
      buscarEstabelecimentos(),
    ])
      .then(([u, m, todos, estabs]) => {
        if (!vivo) return;
        setUsuario(u);
        setMetricas(m);
        setAdmins((todos || []).filter((x) => x.tipoUsuario === "Administrador"));
        setEstabelecimentos(estabs || []);
      })
      .catch((e) => vivo && setErro(e.message))
      .finally(() => vivo && setCarregando(false));
    return () => {
      vivo = false;
    };
  }, [id, meuId]);

  useEffect(() => {
    if (!aviso) return;
    const t = setTimeout(() => setAviso(null), 3200);
    return () => clearTimeout(t);
  }, [aviso]);

  const salvar = async (dados) => {
    const atualizado = await atualizarPerfil(meuId, dados);
    setUsuario(atualizado);
    if (dados.nome) localStorage.setItem("nomeUsuario", dados.nome);
    setEditando(false);
    setAviso("Perfil atualizado.");
  };

  const confirmarDesativacao = async () => {
    const estabelecimento = confirmandoDesativacao;
    if (!estabelecimento || !souPrincipal) return;

    setDesativandoId(estabelecimento.id);
    try {
      await desativarEstabelecimento(estabelecimento.id);
      setEstabelecimentos((atuais) =>
        atuais.map((item) =>
          item.id === estabelecimento.id ? { ...item, ativo: 0 } : item,
        ),
      );
      setConfirmandoDesativacao(null);
      setAviso(`${estabelecimento.nome} foi desativado.`);
    } catch (e) {
      setAviso(e.message || "Não foi possível desativar o estabelecimento.");
    } finally {
      setDesativandoId(null);
    }
  };

  const pedirRemocao = (admin) => {
    setConfirmandoRemocao(admin);
    setCodigoRemocao("");
  };

  const cancelarRemocao = () => {
    setConfirmandoRemocao(null);
    setCodigoRemocao("");
  };

  const confirmarRemocao = async () => {
    const admin = confirmandoRemocao;
    if (!admin || !souPrincipal || admin.estabelecimentoId == null) return;

    setRemovendoId(admin.id);
    try {
      await removerAdministrador(admin.estabelecimentoId, admin.id, codigoRemocao);
      setAdmins((atuais) => atuais.filter((a) => a.id !== admin.id));
      setConfirmandoRemocao(null);
      setCodigoRemocao("");
      setAviso(`${admin.nome} foi removido da equipe.`);
    } catch (e) {
      setAviso(e.message || "Não foi possível remover o administrador.");
    } finally {
      setRemovendoId(null);
    }
  };

  // Só separa por estabelecimento quando o admin principal tem mais de um —
  // com um só, a lista plana de sempre já é suficiente.
  const multiplosEstabelecimentos = estabelecimentos.length > 1;

  const adminsPorEstabelecimento = useMemo(() => {
    if (!multiplosEstabelecimentos) return null;
    const mapa = new Map();
    admins.forEach((a) => {
      const chave = a.estabelecimentoId ?? "sem-estabelecimento";
      if (!mapa.has(chave)) {
        mapa.set(chave, {
          chave,
          nome: a.estabelecimentoNome || "Sem estabelecimento",
          itens: [],
        });
      }
      mapa.get(chave).itens.push(a);
    });
    return [...mapa.values()].sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));
  }, [admins, multiplosEstabelecimentos]);

  if (carregando) return <EstadoCarregando />;
  if (erro) return <EstadoErro mensagem={erro} />;

  const ativos = estabelecimentos.filter((e) => e.ativo === 1).length;

  return (
    <>
      <Topo titulo="Perfil e equipe" sub="Sua conta, os administradores e os locais vinculados">
        <button type="button" className="adm-btn" onClick={() => setEditando(true)}>
          <Icone d={IC.lapis} size={13} />
          Editar perfil
        </button>
      </Topo>

      <section className="per-cabecalho">
        <span
          className="per-avatar"
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
        <div className="per-identidade">
          <h2 className="per-nome">
            {usuario.nome || "Sem nome"}
            <span className="per-tag">{usuario.tipoUsuario || "—"}</span>
            {souPrincipal && <span className="per-tag per-tag-principal">Admin principal</span>}
          </h2>
          <p className="per-email">{usuario.email || "—"}</p>
          <p className="per-id adm-num">ID #{usuario.id}</p>
        </div>
        <dl className="per-stats">
          <div>
            <dt>Estabelecimentos</dt>
            <dd className="adm-num">{metricas.totalEstabelecimentos ?? 0}</dd>
          </div>
          <div>
            <dt>Pendentes</dt>
            <dd className="adm-num">{metricas.pendentes ?? 0}</dd>
          </div>
          <div>
            <dt>Administradores</dt>
            <dd className="adm-num">{metricas.totalAdmins ?? 0}</dd>
          </div>
          <div>
            <dt>Clientes</dt>
            <dd className="adm-num">{metricas.totalUsuarios ?? 0}</dd>
          </div>
        </dl>
      </section>

      <div className="per-grade">
        <div className="per-col">
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Dados da conta</h2>
            </div>
            <dl className="per-dados">
              <Linha rotulo="Nome" valor={usuario.nome} />
              <Linha rotulo="E-mail" valor={usuario.email} />
              <Linha rotulo="Telefone" valor={usuario.telefone} />
              <Linha rotulo="Plano" valor={usuario.nomePlano} />
            </dl>
          </section>

          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Ir para</h2>
            </div>
            <div className="per-atalhos">
              <Atalho para="/sugestoes" icone={IC.chat} titulo="Sugestões" sub="Triar e responder" />
              <Atalho para="/estatisticas" icone={IC.barras} titulo="Estatísticas" sub="Volume e categorias" />
              <Atalho para="/estabelecimentos" icone={IC.predios} titulo="Estabelecimentos" sub="Cadastrar e editar" />
              {souPrincipal && (
                <Atalho para="/plano" icone={IC.estrela} titulo="Plano" sub="Ver e trocar o plano" />
              )}
            </div>
          </section>
        </div>

        <div className="per-col">
          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Administradores</h2>
              <span className="adm-cartao-nota adm-num">{admins.length}</span>
            </div>
            {admins.length === 0 ? (
              <p className="adm-vazio">Nenhum administrador cadastrado.</p>
            ) : adminsPorEstabelecimento ? (
              <div className="per-admins-grupos">
                {adminsPorEstabelecimento.map((grupo) => (
                  <div key={grupo.chave} className="per-admin-grupo">
                    <div className="per-admin-grupo-titulo">
                      <Icone d={IC.predios} size={11} />
                      {grupo.nome}
                      <span className="adm-num">{grupo.itens.length}</span>
                    </div>
                    <ListaAdmins
                      itens={grupo.itens}
                      meuId={meuId}
                      souPrincipal={souPrincipal}
                      removendoId={removendoId}
                      onRemover={pedirRemocao}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <ListaAdmins
                itens={admins}
                meuId={meuId}
                souPrincipal={souPrincipal}
                removendoId={removendoId}
                onRemover={pedirRemocao}
              />
            )}
          </section>

          <section className="adm-cartao">
            <div className="adm-cartao-topo">
              <h2 className="adm-cartao-titulo">Estabelecimentos vinculados</h2>
              <span className="adm-cartao-nota adm-num">
                {ativos} {ativos === 1 ? "ativo" : "ativos"}
              </span>
            </div>
            {estabelecimentos.length === 0 ? (
              <p className="adm-vazio">Nenhum estabelecimento vinculado.</p>
            ) : (
              <ul className="per-estabs">
                {estabelecimentos.map((e) => (
                  <li key={e.id} className="per-estab">
                    <span className="per-estab-info">
                      <span className="per-estab-nome">{e.nome}</span>
                      <span className="per-estab-meta">
                        {[e.cidade, e.categoria].filter(Boolean).join(" · ") || "—"}
                      </span>
                    </span>
                    <span className="per-estab-num adm-num" title="Sugestões recebidas">
                      {e.totalSugestoes ?? 0}
                    </span>
                    <span
                      className={`per-estab-tag${e.ativo === 1 ? " ativo" : ""}`}
                    >
                      {e.ativo === 1 ? "Ativo" : "Inativo"}
                    </span>
                    {souPrincipal && e.ativo === 1 && (
                      <button
                        type="button"
                        className="per-estab-desativar"
                        onClick={() => setConfirmandoDesativacao(e)}
                        title={`Desativar ${e.nome}`}
                      >
                        <Icone d={IC.lixeira} size={13} />
                        Desativar
                      </button>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>
      </div>

      {editando && (
        <ModalEdicao
          usuario={usuario}
          onFechar={() => setEditando(false)}
          onSalvar={salvar}
        />
      )}

      {confirmandoDesativacao && (
        <ModalDesativacao
          estabelecimento={confirmandoDesativacao}
          desativando={desativandoId === confirmandoDesativacao.id}
          onFechar={() => setConfirmandoDesativacao(null)}
          onConfirmar={confirmarDesativacao}
        />
      )}

      {confirmandoRemocao && (
        <ModalRemoverAdmin
          admin={confirmandoRemocao}
          codigo={codigoRemocao}
          onCodigoChange={setCodigoRemocao}
          removendo={removendoId === confirmandoRemocao.id}
          onFechar={cancelarRemocao}
          onConfirmar={confirmarRemocao}
        />
      )}

      {aviso && <div className="per-aviso">{aviso}</div>}
    </>
  );
}

function ListaAdmins({ itens, meuId, souPrincipal, removendoId, onRemover }) {
  return (
    <ul className="per-admins">
      {itens.map((a) => (
        <li key={a.id} className="per-admin">
          <span className="per-admin-avatar">{iniciais(a.nome)}</span>
          <span className="per-admin-info">
            <span className="per-admin-nome">
              {a.nome}
              {a.principal && <span className="per-admin-principal">principal</span>}
              {String(a.id) === String(meuId) && <span className="per-admin-voce">você</span>}
            </span>
            <span className="per-admin-email">{a.email}</span>
          </span>
          {a.cargo && <span className="per-admin-cargo">{a.cargo}</span>}
          {souPrincipal && !a.principal && a.estabelecimentoId != null && (
            <button
              type="button"
              className="per-admin-remover"
              onClick={() => onRemover(a)}
              disabled={removendoId === a.id}
              title={`Remover ${a.nome} da equipe`}
            >
              <Icone d={IC.x} size={12} />
            </button>
          )}
        </li>
      ))}
    </ul>
  );
}

function ModalRemoverAdmin({ admin, codigo, onCodigoChange, removendo, onFechar, onConfirmar }) {
  useEffect(() => {
    const fechar = (e) => e.key === "Escape" && !removendo && onFechar();
    document.addEventListener("keydown", fechar);
    return () => document.removeEventListener("keydown", fechar);
  }, [removendo, onFechar]);

  return (
    <div
      className="per-modal-fundo"
      onMouseDown={(e) => e.target === e.currentTarget && !removendo && onFechar()}
    >
      <div className="per-modal per-modal-perigo" role="dialog" aria-modal="true">
        <div className="per-modal-topo">
          <h2 className="adm-cartao-titulo">Remover da equipe</h2>
          <button
            type="button"
            className="per-modal-fechar"
            onClick={onFechar}
            disabled={removendo}
            aria-label="Fechar"
          >
            <Icone d={IC.x} size={14} />
          </button>
        </div>
        <div className="per-modal-alerta">
          <Icone d={IC.alerta} size={18} />
          <p>
            Tem certeza de que deseja remover <strong>{admin.nome}</strong> da equipe de{" "}
            <strong>{admin.estabelecimentoNome || "estabelecimento"}</strong>? A pessoa perde o
            acesso ao painel administrativo desse local.
          </p>
        </div>
        <label className="per-campo">
          <span className="adm-rotulo">Código da equipe (confirmação)</span>
          <input
            className="adm-campo"
            placeholder="SGT-XXXXXX"
            value={codigo}
            onChange={(e) => onCodigoChange(e.target.value)}
            autoFocus
          />
        </label>
        <div className="per-modal-acoes">
          <button type="button" className="adm-btn" onClick={onFechar} disabled={removendo}>
            Cancelar
          </button>
          <button
            type="button"
            className="adm-btn per-btn-perigo"
            onClick={onConfirmar}
            disabled={removendo || !codigo.trim()}
          >
            {removendo ? "Removendo…" : "Sim, remover"}
          </button>
        </div>
      </div>
    </div>
  );
}

function ModalDesativacao({ estabelecimento, desativando, onFechar, onConfirmar }) {
  useEffect(() => {
    const fechar = (e) => e.key === "Escape" && !desativando && onFechar();
    document.addEventListener("keydown", fechar);
    return () => document.removeEventListener("keydown", fechar);
  }, [desativando, onFechar]);

  return (
    <div
      className="per-modal-fundo"
      onMouseDown={(e) => e.target === e.currentTarget && !desativando && onFechar()}
    >
      <div className="per-modal per-modal-perigo" role="dialog" aria-modal="true">
        <div className="per-modal-topo">
          <h2 className="adm-cartao-titulo">Desativar estabelecimento</h2>
          <button
            type="button"
            className="per-modal-fechar"
            onClick={onFechar}
            disabled={desativando}
            aria-label="Fechar"
          >
            <Icone d={IC.x} size={14} />
          </button>
        </div>
        <div className="per-modal-alerta">
          <Icone d={IC.alerta} size={18} />
          <p>
            Tem certeza de que deseja desativar <strong>{estabelecimento.nome}</strong>?
            O local deixará de aparecer para os clientes.
          </p>
        </div>
        <p className="per-modal-nota">
          Os dados serão mantidos e o estabelecimento ficará marcado como inativo.
        </p>
        <div className="per-modal-acoes">
          <button type="button" className="adm-btn" onClick={onFechar} disabled={desativando}>
            Cancelar
          </button>
          <button
            type="button"
            className="adm-btn per-btn-perigo"
            onClick={onConfirmar}
            disabled={desativando}
          >
            {desativando ? "Desativando…" : "Sim, desativar"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Linha({ rotulo, valor }) {
  return (
    <div className="per-dado">
      <dt>{rotulo}</dt>
      <dd>{valor || <span className="per-vazio">não informado</span>}</dd>
    </div>
  );
}

function Atalho({ para, icone, titulo, sub }) {
  return (
    <Link to={para} className="per-atalho">
      <span className="per-atalho-ico">
        <Icone d={icone} size={15} />
      </span>
      <span className="per-atalho-txt">
        <strong>{titulo}</strong>
        <small>{sub}</small>
      </span>
      <Icone d={IC.seta} size={14} className="per-atalho-seta" />
    </Link>
  );
}

// E-mail não é editável por aqui.
function ModalEdicao({ usuario, onFechar, onSalvar }) {
  const [nome, setNome] = useState(usuario.nome || "");
  const [telefone, setTelefone] = useState(usuario.telefone || "");
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState(null);

  useEffect(() => {
    const fechar = (e) => e.key === "Escape" && onFechar();
    document.addEventListener("keydown", fechar);
    return () => document.removeEventListener("keydown", fechar);
  }, [onFechar]);

  const enviar = async (e) => {
    e.preventDefault();
    if (!nome.trim()) {
      setErro("O nome não pode ficar vazio.");
      return;
    }
    setSalvando(true);
    setErro(null);
    try {
      await onSalvar({ nome: nome.trim(), telefone: telefone.trim() });
    } catch (err) {
      setErro(err.message);
      setSalvando(false);
    }
  };

  return (
    <div className="per-modal-fundo" onMouseDown={(e) => e.target === e.currentTarget && onFechar()}>
      <form className="per-modal" onSubmit={enviar}>
        <div className="per-modal-topo">
          <h2 className="adm-cartao-titulo">Editar perfil</h2>
          <button type="button" className="per-modal-fechar" onClick={onFechar}>
            <Icone d={IC.x} size={14} />
          </button>
        </div>

        <label className="per-campo">
          <span className="adm-rotulo">Nome</span>
          <input
            className="adm-campo"
            value={nome}
            onChange={(e) => setNome(e.target.value)}
            autoFocus
          />
        </label>
        <label className="per-campo">
          <span className="adm-rotulo">Telefone</span>
          <input
            className="adm-campo"
            value={telefone}
            onChange={(e) => setTelefone(e.target.value)}
            placeholder="(19) 99999-0000"
          />
        </label>
        <p className="per-modal-nota">
          O e-mail não é editável por aqui.
        </p>

        {erro && <div className="adm-erro">{erro}</div>}

        <div className="per-modal-acoes">
          <button type="button" className="adm-btn" onClick={onFechar}>
            Cancelar
          </button>
          <button type="submit" className="adm-btn adm-btn-principal" disabled={salvando}>
            {salvando ? "Salvando…" : "Salvar"}
          </button>
        </div>
      </form>
    </div>
  );
}
