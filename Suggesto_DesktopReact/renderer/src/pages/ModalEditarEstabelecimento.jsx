import React, { useState, useEffect, useRef } from "react";
import './ModalEstabelecimento.css';
import './ModalEditarEstabelecimento.css';
import Icone, { IC } from "../components/Icones";
import { API_BASE, buscarUsuarios, urlFoto } from "../api/admin";

const CATEGORIAS = [
  "Restaurante", "Bar", "Lanchonete", "Pizzaria",
  "Cafeteria", "Padaria", "Sorveteria", "Outro",
];

// Extrai o primeiro e o último horário citados no texto livre salvo no banco
// (ex: "Seg. a Dom.: 11:00 – 22:30"), para pré-preencher os campos de hora.
function extrairHorarios(horarioTexto) {
  const horarios = String(horarioTexto || "").match(/(\d{1,2}):(\d{2})/g);
  if (!horarios || horarios.length < 2) return { abertura: "", fechamento: "" };
  return { abertura: horarios[0], fechamento: horarios[horarios.length - 1] };
}

export default function ModalEditarEstabelecimento({ estab, fecharModal, aoSalvar }) {
  const horariosIniciais = extrairHorarios(estab.horarioFuncionamento);

  const [nome, setNome] = useState(estab.nome || "");
  const [cnpj, setCnpj] = useState(estab.cnpj || "");
  const [categoria, setCategoria] = useState(estab.categoria || "");
  const [telefone, setTelefone] = useState(estab.telefone || "");
  const [sobre, setSobre] = useState(estab.sobre || "");
  const [horarioAbertura, setHorarioAbertura] = useState(horariosIniciais.abertura);
  const [horarioFechamento, setHorarioFechamento] = useState(horariosIniciais.fechamento);
  const [endereco, setEndereco] = useState({
    cep: estab.cep || "",
    estado: estab.estado || "",
    cidade: estab.cidade || "",
    bairro: estab.bairro || "",
    rua: estab.rua || "",
    numero: estab.numero || "",
    complemento: estab.complemento || "",
  });

  const [arquivo, setArquivo] = useState(null);
  const [preview, setPreview] = useState(urlFoto(estab.fotoPath));
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef();

  const [admins, setAdmins] = useState([]);
  const [removendoId, setRemovendoId] = useState(null);
  const [confirmandoRemocaoId, setConfirmandoRemocaoId] = useState(null);
  const [codigoRemocao, setCodigoRemocao] = useState("");
  const [codigoConfirmacao, setCodigoConfirmacao] = useState("");
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState(null);

  const meuId = localStorage.getItem("idUsuario");

  useEffect(() => {
    let vivo = true;
    buscarUsuarios()
      .then((todos) => {
        if (!vivo) return;
        setAdmins((todos || []).filter((a) => a.tipoUsuario === "Administrador"));
      })
      .catch(() => {});
    return () => { vivo = false; };
  }, []);

  const lidarComEndereco = (e) => {
    const { name, value } = e.target;
    setEndereco((prev) => ({ ...prev, [name]: value }));
  };

  const lidarComCep = async (e) => {
    let valor = e.target.value.replace(/\D/g, "").slice(0, 8);
    if (valor.length > 5) valor = valor.replace(/^(\d{5})(\d)/, "$1-$2");
    setEndereco((prev) => ({ ...prev, cep: valor }));

    const cepLimpo = valor.replace(/\D/g, "");
    if (cepLimpo.length === 8) {
      try {
        const resposta = await fetch(`https://viacep.com.br/ws/${cepLimpo}/json/`);
        const dados = await resposta.json();
        if (!dados.erro) {
          setEndereco((prev) => ({
            ...prev,
            rua: dados.logradouro || "",
            bairro: dados.bairro || "",
            cidade: dados.localidade || "",
            estado: dados.uf || "",
          }));
        }
      } catch (error) {
        console.error("Erro ao buscar CEP:", error);
      }
    }
  };

  const mascaraCnpj = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 14);
    return n
      .replace(/^(\d{2})(\d)/, "$1.$2")
      .replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3")
      .replace(/\.(\d{3})(\d)/, ".$1/$2")
      .replace(/(\d{4})(\d)/, "$1-$2");
  };

  const mascaraTel = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 11);
    if (n.length <= 10) return n.replace(/^(\d{2})(\d{4})(\d{0,4})/, "($1) $2-$3");
    return n.replace(/^(\d{2})(\d{5})(\d{0,4})/, "($1) $2-$3");
  };

  const aplicarArquivo = (file) => {
    if (!file) return;
    setArquivo(file);
    setPreview(URL.createObjectURL(file));
  };

  const handleFile = (e) => aplicarArquivo(e.target.files[0]);
  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    aplicarArquivo(e.dataTransfer.files[0]);
  };

  const handleSalvar = async (e) => {
    e.preventDefault();
    setSalvando(true);
    setErro(null);

    const horarioFuncionamento =
      horarioAbertura && horarioFechamento
        ? `Seg. a Dom.: ${horarioAbertura} – ${horarioFechamento}`
        : "";

    const payload = {
      nome, cnpj, categoria, telefone, horarioFuncionamento, sobre,
      ...endereco,
    };

    const formData = new FormData();
    formData.append("estabelecimento", new Blob([JSON.stringify(payload)], { type: "application/json" }));
    if (arquivo) formData.append("foto", arquivo);

    try {
      const url = `${API_BASE}/estabelecimentos/${estab.idEstabelecimento}`
        + `?idSolicitante=${meuId}&codigoConfirmacao=${encodeURIComponent(codigoConfirmacao.trim())}`;
      const r = await fetch(url, {
        method: "PUT",
        body: formData,
      });
      if (r.ok) {
        aoSalvar(await r.json());
        fecharModal();
      } else {
        setErro(await r.text());
      }
    } catch {
      setErro("Erro de comunicação com o servidor.");
    } finally {
      setSalvando(false);
    }
  };

  const pedirConfirmacaoRemocao = (idUsuario) => {
    setConfirmandoRemocaoId(idUsuario);
    setCodigoRemocao("");
  };

  const cancelarRemocao = () => {
    setConfirmandoRemocaoId(null);
    setCodigoRemocao("");
  };

  const confirmarRemocao = async (idUsuario) => {
    setRemovendoId(idUsuario);
    try {
      const url = `${API_BASE}/estabelecimentos/${estab.idEstabelecimento}/administradores/${idUsuario}`
        + `?idSolicitante=${meuId}&codigoConfirmacao=${encodeURIComponent(codigoRemocao.trim())}`;
      const r = await fetch(url, { method: "DELETE" });
      if (r.ok) {
        setAdmins((prev) => prev.filter((a) => a.id !== idUsuario));
        cancelarRemocao();
      } else {
        const dados = await r.json().catch(() => null);
        alert(dados?.message || "Erro ao remover administrador.");
      }
    } catch {
      alert("Erro de comunicação com o servidor.");
    } finally {
      setRemovendoId(null);
    }
  };

  return (
    <>
      <div className="modal-overlay" onClick={fecharModal} />

      <div className="modal-painel">
        <div className="modal-glow-1" />
        <div className="modal-glow-2" />

        <div className="modal-header">
          <div className="header-left">
            <div className="logo-icon"><Icone d={IC.predios} size={16} /></div>
            <div>
              <h2 className="modal-titulo">Editar estabelecimento</h2>
              <p className="modal-subtitulo">Atualize os dados, horário, foto e equipe</p>
            </div>
          </div>
          <button className="btn-fechar" onClick={fecharModal}>
            <Icone d={IC.x} size={16} />
          </button>
        </div>

        <div className="modal-divider" />

        <form onSubmit={handleSalvar} className="modal-form">
          <div className="form-grid-2">
            <Campo label="Nome do local" required>
              <input className="form-input" value={nome} onChange={(e) => setNome(e.target.value)} required />
            </Campo>
            <Campo label="Categoria" required>
              <select className="form-input form-select" value={categoria} onChange={(e) => setCategoria(e.target.value)} required>
                <option value="" disabled>Selecione...</option>
                {CATEGORIAS.map((c) => <option key={c} value={c}>{c}</option>)}
              </select>
            </Campo>
          </div>

          <div className="form-grid-cep-numero">
            <Campo label="CEP" required>
              <input className="form-input" name="cep" value={endereco.cep} onChange={lidarComCep} required />
            </Campo>
            <Campo label="Número" required>
              <input className="form-input" name="numero" value={endereco.numero} onChange={lidarComEndereco} required />
            </Campo>
          </div>

          <Campo label="Rua / Logradouro" required>
            <input className="form-input" name="rua" value={endereco.rua} onChange={lidarComEndereco} required />
          </Campo>

          <div className="form-grid-2">
            <Campo label="Bairro" required>
              <input className="form-input" name="bairro" value={endereco.bairro} onChange={lidarComEndereco} required />
            </Campo>
            <Campo label="Complemento">
              <input className="form-input" name="complemento" value={endereco.complemento} onChange={lidarComEndereco} />
            </Campo>
          </div>

          <div className="form-grid-cidade-estado">
            <Campo label="Cidade" required>
              <input className="form-input" name="cidade" value={endereco.cidade} onChange={lidarComEndereco} required />
            </Campo>
            <Campo label="Estado (UF)" required>
              <input className="form-input" name="estado" value={endereco.estado} onChange={lidarComEndereco} required />
            </Campo>
          </div>

          <div className="form-grid-2">
            <Campo label="CNPJ" required>
              <input className="form-input" value={cnpj} onChange={(e) => setCnpj(mascaraCnpj(e.target.value))} required />
            </Campo>
            <Campo label="Telefone" required>
              <input className="form-input" value={telefone} onChange={(e) => setTelefone(mascaraTel(e.target.value))} required />
            </Campo>
          </div>

          <div className="form-grid-2">
            <Campo label="Abre às">
              <input type="time" className="form-input" value={horarioAbertura} onChange={(e) => setHorarioAbertura(e.target.value)} />
            </Campo>
            <Campo label="Fecha às">
              <input type="time" className="form-input" value={horarioFechamento} onChange={(e) => setHorarioFechamento(e.target.value)} />
            </Campo>
          </div>

          <Campo label="Sobre o estabelecimento">
            <textarea
              className="form-input form-textarea"
              placeholder="Conte a história do local, o que vocês servem, o que torna o lugar especial…"
              value={sobre}
              onChange={(e) => setSobre(e.target.value)}
              rows={4}
              maxLength={1000}
            />
            <p className="edit-codigo-nota">
              Esse texto aparece na aba “Sobre” da página do estabelecimento no site.
            </p>
          </Campo>

          <Campo label="Foto do estabelecimento">
            <div
              className={`dropzone ${dragOver ? 'ativo' : ''}`}
              onClick={() => fileRef.current.click()}
              onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
              onDragLeave={() => setDragOver(false)}
              onDrop={handleDrop}
            >
              {preview ? (
                <div className="preview-wrap">
                  <img src={preview} alt="preview" className="preview-img" />
                  <div className="preview-overlay">
                    <span className="preview-troca">Trocar imagem</span>
                  </div>
                </div>
              ) : (
                <div className="drop-content">
                  <div className="drop-icon"><Icone d={IC.baixar} size={22} /></div>
                  <p className="drop-title">Arraste ou clique para enviar</p>
                  <p className="drop-sub">PNG, JPG, WEBP — máx. 5 MB</p>
                </div>
              )}
              <input ref={fileRef} type="file" accept="image/*" onChange={handleFile} style={{ display: "none" }} />
            </div>
          </Campo>

          <div className="modal-divider" />

          <Campo label="Administradores vinculados">
            {admins.length === 0 ? (
              <p className="edit-admins-vazio">Nenhum administrador vinculado.</p>
            ) : (
              <ul className="edit-admins-lista">
                {admins.map((a) => (
                  <li key={a.id} className="edit-admin-item">
                    <span className="edit-admin-info">
                      <span className="edit-admin-nome">
                        {a.nome}
                        {a.principal && <span className="edit-admin-tag">principal</span>}
                      </span>
                      <span className="edit-admin-email">{a.email}</span>
                    </span>
                    {!a.principal && confirmandoRemocaoId === a.id ? (
                      <span className="edit-admin-confirmacao">
                        <input
                          type="text"
                          className="form-input edit-admin-codigo"
                          placeholder="Código da equipe"
                          value={codigoRemocao}
                          onChange={(e) => setCodigoRemocao(e.target.value)}
                          autoFocus
                        />
                        <button
                          type="button"
                          className="edit-admin-remover"
                          title="Confirmar remoção"
                          onClick={() => confirmarRemocao(a.id)}
                          disabled={removendoId === a.id || !codigoRemocao.trim()}
                        >
                          {removendoId === a.id ? "…" : <Icone d={IC.check} size={13} />}
                        </button>
                        <button
                          type="button"
                          className="edit-admin-cancelar"
                          title="Cancelar"
                          onClick={cancelarRemocao}
                          disabled={removendoId === a.id}
                        >
                          <Icone d={IC.x} size={13} />
                        </button>
                      </span>
                    ) : (
                      !a.principal && (
                        <button
                          type="button"
                          className="edit-admin-remover"
                          title="Remover da equipe"
                          onClick={() => pedirConfirmacaoRemocao(a.id)}
                        >
                          <Icone d={IC.x} size={13} />
                        </button>
                      )
                    )}
                  </li>
                ))}
              </ul>
            )}
          </Campo>

          <div className="modal-divider" />

          <Campo label="Código da equipe (confirmação)" required>
            <input
              className="form-input"
              placeholder="SGT-XXXXXX"
              value={codigoConfirmacao}
              onChange={(e) => setCodigoConfirmacao(e.target.value)}
              required
            />
            <p className="edit-codigo-nota">
              Confirme o código do estabelecimento para salvar as alterações.
            </p>
          </Campo>

          {erro && <div className="edit-erro">{erro}</div>}

          <div className="modal-footer">
            <button type="button" className="btn-cancelar" onClick={fecharModal}>Cancelar</button>
            <button type="submit" className="btn-salvar" disabled={salvando}>
              {salvando ? (<><span className="spinner" /> Salvando...</>) : (<><Icone d={IC.check} size={15} /> Salvar</>)}
            </button>
          </div>
        </form>
      </div>
    </>
  );
}

function Campo({ label, required, children }) {
  return (
    <div className="campo-wrapper">
      <label className="form-label">
        {label}
        {required && <span className="asterisco">*</span>}
      </label>
      {children}
    </div>
  );
}
