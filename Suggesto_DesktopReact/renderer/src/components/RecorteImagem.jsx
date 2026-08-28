import React, { useCallback, useState } from "react";
import Cropper from "react-easy-crop";
import "./RecorteImagem.css";

// Modal de recorte de imagem — usado no criar/editar estabelecimento
// (ModalEstabelecimento.jsx / ModalEditarEstabelecimento.jsx).
//
// `aspect` é largura/altura do recorte (1 = quadrado, 300/180 = mesma
// proporção do card de estabelecimento em .local-imagem). `redondo` deixa a
// área de recorte com máscara circular (foto de perfil) — a saída continua
// sendo um arquivo retangular/quadrado, só a aparência do recorte é redonda,
// igual ao avatar já é exibido depois (border-radius: 50%).
//
// `urlImagem` é sempre um object URL local (URL.createObjectURL do arquivo
// escolhido), nunca uma URL remota — então não tem questão de CORS no canvas.
export default function RecorteImagem({ arquivo, urlImagem, aspect = 1, redondo = false, onConfirmar, onCancelar }) {
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [areaRecorte, setAreaRecorte] = useState(null);
  const [processando, setProcessando] = useState(false);

  const aoCompletarCorte = useCallback((_areaPercentual, areaPixels) => {
    setAreaRecorte(areaPixels);
  }, []);

  async function confirmar() {
    if (!areaRecorte || processando) return;
    setProcessando(true);
    try {
      const blob = await recortarParaBlob(urlImagem, areaRecorte, aspect);
      const tipo = blob.type || arquivo?.type || "image/jpeg";
      const nome = arquivo?.name || "foto.jpg";
      onConfirmar(new File([blob], nome, { type: tipo }));
    } catch (e) {
      console.error("Erro ao recortar imagem:", e);
    } finally {
      setProcessando(false);
    }
  }

  return (
    <div
      className="recorte-overlay"
      onClick={(e) => {
        if (e.target === e.currentTarget) onCancelar();
      }}
    >
      <div className="recorte-modal">
        <div className="recorte-topo">
          <h3>Ajustar foto</h3>
          <button type="button" className="recorte-fechar" onClick={onCancelar} aria-label="Cancelar">
            &times;
          </button>
        </div>

        <div className="recorte-area">
          <Cropper
            image={urlImagem}
            crop={crop}
            zoom={zoom}
            aspect={aspect}
            cropShape={redondo ? "round" : "rect"}
            onCropChange={setCrop}
            onZoomChange={setZoom}
            onCropComplete={aoCompletarCorte}
          />
        </div>

        <div className="recorte-zoom">
          <input
            type="range"
            min={1}
            max={4}
            step={0.01}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
          />
        </div>

        <div className="recorte-acoes">
          <button type="button" className="adm-btn" onClick={onCancelar} disabled={processando}>
            Cancelar
          </button>
          <button
            type="button"
            className="adm-btn adm-btn-principal"
            onClick={confirmar}
            disabled={processando || !areaRecorte}
          >
            {processando ? "Processando..." : "Usar foto"}
          </button>
        </div>
      </div>
    </div>
  );
}

// Recorta a imagem via canvas usando a área (em pixels) que o react-easy-crop
// devolve em onCropComplete — receita padrão da documentação da lib.
function recortarParaBlob(urlImagem, area, aspect) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const alturaSaida = 1000;
      const larguraSaida = Math.round(alturaSaida * aspect);
      const canvas = document.createElement("canvas");
      canvas.width = larguraSaida;
      canvas.height = alturaSaida;
      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, area.x, area.y, area.width, area.height, 0, 0, larguraSaida, alturaSaida);
      canvas.toBlob(
        (blob) => (blob ? resolve(blob) : reject(new Error("Não foi possível gerar a imagem recortada."))),
        "image/jpeg",
        0.92,
      );
    };
    img.onerror = () => reject(new Error("Não foi possível carregar a imagem."));
    img.src = urlImagem;
  });
}
