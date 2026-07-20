import React, { useState, useRef } from "react";
import './ModalEstabelecimento.css'; // Importando o CSS separado

// ─── ÍCONE INLINE ─────────────────────────────────────────────────────────────
const Icon = ({ d, size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
    stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d={d} />
  </svg>
);
const IC = {
  close:   "M18 6L6 18M6 6l12 12",
  upload:  "M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12",
  check:   "M20 6L9 17l-5-5",
  img:     "M21 19a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z M12 13a3 3 0 100-6 3 3 0 000 6z",
  logo:    "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5",
};

const CATEGORIAS = [
  "Restaurante", "Bar", "Lanchonete", "Pizzaria",
  "Cafeteria", "Padaria", "Sorveteria", "Outro",
];

/* ─── FUNÇÕES AUXILIARES DE VALIDAÇÃO MATEMÁTICA ────────────────────────── */
const validarCNPJ = (cnpj) => {
  const numeros = cnpj.replace(/[^\d]+/g, '');
  if (numeros.length !== 14) return false;
  if (/^(\d)\1+$/.test(numeros)) return false;

  let tamanho = numeros.length - 2;
  let numerosBase = numeros.substring(0, tamanho);
  const digitosVerificadores = numeros.substring(tamanho);
  let soma = 0;
  let pos = tamanho - 7;

  for (let i = tamanho; i >= 1; i--) {
    soma += numerosBase.charAt(tamanho - i) * pos--;
    if (pos < 2) pos = 9;
  }

  let resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
  if (resultado !== parseInt(digitosVerificadores.charAt(0))) return false;

  tamanho = tamanho + 1;
  numerosBase = numeros.substring(0, tamanho);
  soma = 0;
  pos = tamanho - 7;

  for (let i = tamanho; i >= 1; i--) {
    soma += numerosBase.charAt(tamanho - i) * pos--;
    if (pos < 2) pos = 9;
  }

  resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
  if (resultado !== parseInt(digitosVerificadores.charAt(1))) return false;

  return true;
};

const validarTelefone = (telefone) => {
  const numeros = telefone.replace(/[^\d]+/g, '');
  return numeros.length === 10 || numeros.length === 11;
};

/* ─── COMPONENTE PRINCIPAL ───────────────────────────────────────────────────── */
export default function ModalEstabelecimento({ fecharModal, aoSalvar }) {
  const [nome,      setNome]      = useState("");
  const [cnpj,      setCnpj]      = useState("");
  const [categoria, setCategoria] = useState("");
  const [telefone,  setTelefone]  = useState("");
  const [horarioAbertura,   setHorarioAbertura]   = useState("");
  const [horarioFechamento, setHorarioFechamento] = useState("");
  const [arquivo,   setArquivo]   = useState(null);
  const [preview,   setPreview]   = useState(null);
  const [salvando,  setSalvando]  = useState(false);
  const [dragOver,  setDragOver]  = useState(false);
  
  // Estados para capturar erros de validação local
  const [cnpjInvalido, setCnpjInvalido] = useState(false);
  const [telefoneInvalido, setTelefoneInvalido] = useState(false);
  
  const fileRef = useRef();

  // ── Estado do Endereço Estruturado ──────────────────────────────────────────
  const [enderecoCompleto, setEnderecoCompleto] = useState({
    cep: "",
    estado: "",
    cidade: "",
    bairro: "",
    rua: "",
    numero: "",
    complemento: ""
  });

  const lidarComMudancaEndereco = (e) => {
    const { name, value } = e.target;
    setEnderecoCompleto(prev => ({ ...prev, [name]: value }));
  };

  // ── Consulta ViaCEP com Máscara Integrada ───────────────────────────────────
  const lidarComCep = async (e) => {
    let valor = e.target.value.replace(/\D/g, "").slice(0, 8);
    if (valor.length > 5) {
      valor = valor.replace(/^(\d{5})(\d)/, "$1-$2");
    }
    
    setEnderecoCompleto(prev => ({ ...prev, cep: valor }));

    const cepLimpo = valor.replace(/\D/g, "");
    if (cepLimpo.length === 8) {
      try {
        const resposta = await fetch(`https://viacep.com.br/ws/${cepLimpo}/json/`);
        const dadosCep = await resposta.json();
        
        if (!dadosCep.erro) {
          setEnderecoCompleto(prev => ({
            ...prev,
            rua: dadosCep.logradouro || "",
            bairro: dadosCep.bairro || "",
            cidade: dadosCep.localidade || "",
            estado: dadosCep.uf || ""
          }));
          setTimeout(() => document.getElementById("input-numero")?.focus(), 50);
        } else {
          alert("CEP não encontrado. Por favor, digite o endereço manualmente.");
        }
      } catch (error) {
        console.error("Erro ao buscar CEP:", error);
      }
    }
  };

  // ── Gatilhos de validação ao perder o foco (onBlur) ─────────────────────────
  const handleBlurCNPJ = (e) => {
    const valor = e.target.value;
    if (valor) {
      setCnpjInvalido(!validarCNPJ(valor));
    } else {
      setCnpjInvalido(false);
    }
  };

  const handleBlurTelefone = (e) => {
    const valor = e.target.value;
    if (valor) {
      setTelefoneInvalido(!validarTelefone(valor));
    } else {
      setTelefoneInvalido(false);
    }
  };

  // ── Lógica de arquivo ───────────────────────────────────────────────────────
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

  // ── Submissão ───────────────────────────────────────────────────────────────
  const handleSalvar = async (e) => {
    e.preventDefault();
    
    // Bloqueio extra redundante de segurança antes do envio
    if (cnpjInvalido || telefoneInvalido) return;

    setSalvando(true);

    const idGerente = localStorage.getItem("idUsuario");
    if (!idGerente) { 
      alert("Erro: ID do gerente não encontrado."); 
      setSalvando(false); 
      return; 
    }

    const formData = new FormData();

    const horarioFuncionamento =
      horarioAbertura && horarioFechamento
        ? `Seg. a Dom.: ${horarioAbertura} – ${horarioFechamento}`
        : "";

    const payloadEstabelecimento = {
      nome,
      cnpj,
      categoria,
      telefone,
      horarioFuncionamento,
      idGerente,
      ...enderecoCompleto
    };

    formData.append(
      "estabelecimento",
      new Blob([JSON.stringify(payloadEstabelecimento)], { type: "application/json" })
    );
    if (arquivo) formData.append("foto", arquivo);

    try {
      const r = await fetch("http://localhost:8080/api/estabelecimentos", { method: "POST", body: formData });
      if (r.ok) {
        aoSalvar(await r.json());
        fecharModal();
      } else {
        alert("Erro ao guardar: " + await r.text());
      }
    } catch {
      alert("Erro de comunicação com o servidor.");
    } finally {
      setSalvando(false);
    }
  };

  // ── Máscara CNPJ ────────────────────────────────────────────────────────────
  const mascaraCnpj = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 14);
    return n
      .replace(/^(\d{2})(\d)/, "$1.$2")
      .replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3")
      .replace(/\.(\d{3})(\d)/, ".$1/$2")
      .replace(/(\d{4})(\d)/, "$1-$2");
  };

  // ── Máscara Telefone ────────────────────────────────────────────────────────
  const mascaraTel = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 11);
    if (n.length <= 10) return n.replace(/^(\d{2})(\d{4})(\d{0,4})/, "($1) $2-$3");
    return n.replace(/^(\d{2})(\d{5})(\d{0,4})/, "($1) $2-$3");
  };

  return (
    <>
      {/* ── Overlay ───────────────────────────────────────────────────────── */}
      <div className="modal-overlay" onClick={fecharModal} />

      {/* ── Painel ────────────────────────────────────────────────────────── */}
      <div className="modal-painel">

        {/* Glows */}
        <div className="modal-glow-1" />
        <div className="modal-glow-2" />

        {/* ── Cabeçalho ─────────────────────────────────────────────────── */}
        <div className="modal-header">
          <div className="header-left">
            <div className="logo-icon"><Icon d={IC.logo} size={16} /></div>
            <div>
              <h2 className="modal-titulo">Novo Estabelecimento</h2>
              <p className="modal-subtitulo">Preencha os dados para cadastrar</p>
            </div>
          </div>
          <button className="btn-fechar" onClick={fecharModal}>
            <Icon d={IC.close} size={16} />
          </button>
        </div>

        <div className="modal-divider" />

        {/* ── Formulário ────────────────────────────────────────────────── */}
        <form onSubmit={handleSalvar} className="modal-form">
          <div className="form-grid-2">
            <Campo label="Nome do local" required>
              <input className="form-input" value={nome}
                onChange={(e) => setNome(e.target.value)} required
                placeholder="Ex: Café Central" />
            </Campo>

            <Campo label="Categoria" required>
              <select className="form-input form-select"
                value={categoria} onChange={(e) => setCategoria(e.target.value)} required>
                <option value="" disabled>Selecione...</option>
                {CATEGORIAS.map((c) => <option key={c} value={c}>{c}</option>)}
              </select>
            </Campo>
          </div>

          {/* ── Bloco de Endereço via CEP ────────────────────────────────── */}
          <div className="form-grid-cep-numero">
            <Campo label="CEP" required>
              <input className="form-input" name="cep" value={enderecoCompleto.cep}
                onChange={lidarComCep} required placeholder="00000-000" />
            </Campo>

            <Campo label="Número" required>
              <input className="form-input" id="input-numero" name="numero" 
                value={enderecoCompleto.numero} onChange={lidarComMudancaEndereco} 
                required placeholder="123" />
            </Campo>
          </div>

          <Campo label="Rua / Logradouro" required>
            <input className="form-input" name="rua" value={enderecoCompleto.rua}
              onChange={lidarComMudancaEndereco} required placeholder="Avenida Central" />
          </Campo>

          <div className="form-grid-2">
            <Campo label="Bairro" required>
              <input className="form-input" name="bairro" value={enderecoCompleto.bairro}
                onChange={lidarComMudancaEndereco} required placeholder="Centro" />
            </Campo>

            <Campo label="Complemento">
              <input className="form-input" name="complemento" value={enderecoCompleto.complemento}
                onChange={lidarComMudancaEndereco} placeholder="Sala 4, Bloco B (Opcional)" />
            </Campo>
          </div>

          <div className="form-grid-cidade-estado">
            <Campo label="Cidade" required>
              <input className="form-input" name="cidade" value={enderecoCompleto.cidade}
                onChange={lidarComMudancaEndereco} required placeholder="Sua Cidade" disabled />
            </Campo>

            <Campo label="Estado (UF)" required>
              <input className="form-input" name="estado" value={enderecoCompleto.estado}
                onChange={lidarComMudancaEndereco} required placeholder="SP" disabled />
            </Campo>
          </div>
          {/* ─────────────────────────────────────────────────────────────── */}

          <div className="form-grid-2">
            <Campo label="CNPJ" required>
              <input className="form-input" value={cnpj}
                onChange={(e) => {
                  setCnpj(mascaraCnpj(e.target.value));
                  if (cnpjInvalido) setCnpjInvalido(false); // Limpa o aviso enquanto digita novamente
                }} 
                onBlur={handleBlurCNPJ}
                required
                placeholder="00.000.000/0000-00" 
                style={cnpjInvalido ? { borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.04)' } : {}}
              />
              {cnpjInvalido && <span style={{ color: '#ef4444', fontSize: '0.7rem', fontWeight: 600, marginTop: '2px' }}>CNPJ inválido ou inexistente</span>}
            </Campo>

            <Campo label="Telefone" required>
              <input className="form-input" value={telefone}
                onChange={(e) => {
                  setTelefone(mascaraTel(e.target.value));
                  if (telefoneInvalido) setTelefoneInvalido(false); // Limpa o aviso enquanto redigita
                }} 
                onBlur={handleBlurTelefone}
                required
                placeholder="(00) 00000-0000" 
                style={telefoneInvalido ? { borderColor: '#ef4444', background: 'rgba(239, 68, 68, 0.04)' } : {}}
              />
              {telefoneInvalido && <span style={{ color: '#ef4444', fontSize: '0.7rem', fontWeight: 600, marginTop: '2px' }}>Telefone incompleto</span>}
            </Campo>
          </div>

          {/* ── Horário de funcionamento ─────────────────────────────────── */}
          <div className="form-grid-2">
            <Campo label="Abre às">
              <input type="time" className="form-input" value={horarioAbertura}
                onChange={(e) => setHorarioAbertura(e.target.value)} />
            </Campo>

            <Campo label="Fecha às">
              <input type="time" className="form-input" value={horarioFechamento}
                onChange={(e) => setHorarioFechamento(e.target.value)} />
            </Campo>
          </div>

          {/* ── Upload de foto ──────────────────────────────────────────── */}
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
                  <div className="drop-icon"><Icon d={IC.upload} size={22} /></div>
                  <p className="drop-title">Arraste ou clique para enviar</p>
                  <p className="drop-sub">PNG, JPG, WEBP — máx. 5 MB</p>
                </div>
              )}
              <input ref={fileRef} type="file" accept="image/*"
                onChange={handleFile} style={{ display: "none" }} />
            </div>
          </Campo>

          <div className="modal-divider" />

          {/* ── Rodapé ──────────────────────────────────────────────────── */}
          <div className="modal-footer">
            <button type="button" className="btn-cancelar" onClick={fecharModal}>
              Cancelar
            </button>
            <button 
              type="submit" 
              className="btn-salvar" 
              disabled={salvando || cnpjInvalido || telefoneInvalido}
              style={(cnpjInvalido || telefoneInvalido) ? { opacity: 0.4, cursor: 'not-allowed' } : {}}
            >
              {salvando ? (
                <><span className="spinner" /> Registrando...</>
              ) : (
                <><Icon d={IC.check} size={15} /> Registrar</>
              )}
            </button>
          </div>
        </form>
      </div>
    </>
  );
}

// ─── SUB-COMPONENTE: CAMPO ────────────────────────────────────────────────────
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