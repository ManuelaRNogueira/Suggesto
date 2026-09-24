import React, { useEffect, useState } from "react";
import QRCode from "qrcode";
import { gerarNovoTokenCheckin, urlCheckin } from "../api/admin";
import { useAviso } from "./Aviso";
import "./QrCheckin.css";

// QR de check-in que o dono imprime e coloca nas mesas: quem lê com a câmera
// do celular cai na página de avaliação do site com a visita confirmada.
// Não confundir com o código da equipe (codigoAcesso), que nunca vai pra mesa.
export default function QrCheckin({ estab, onTokenAlterado }) {
  const avisar = useAviso();
  const [imagem, setImagem] = useState(null);
  const [confirmando, setConfirmando] = useState(false);
  const [gerando, setGerando] = useState(false);

  const token = estab.tokenCheckin;
  const url = token ? urlCheckin(estab.idEstabelecimento, token) : null;
  const semCoordenadas = estab.lat == null || estab.lng == null;

  useEffect(() => {
    if (!url) return;
    let vivo = true;
    QRCode.toDataURL(url, { width: 480, margin: 1 })
      .then((dados) => vivo && setImagem(dados))
      .catch(() => vivo && setImagem(null));
    return () => {
      vivo = false;
    };
  }, [url]);

  // Imprime por um iframe escondido: no Electron é mais confiável que abrir
  // outra janela, e só o QR sai no papel (não o painel inteiro).
  const imprimir = () => {
    const iframe = document.createElement("iframe");
    iframe.style.cssText = "position:fixed;width:0;height:0;border:0;";
    document.body.appendChild(iframe);
    const doc = iframe.contentDocument;
    doc.open();
    doc.write(`<!doctype html><html><head><title>QR de check-in</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 40px; }
        h1 { font-size: 26px; margin: 0 0 6px; }
        p { font-size: 16px; color: #333; margin: 0 0 24px; }
        img { width: 320px; height: 320px; }
      </style></head><body>
      <h1></h1>
      <p>Aponte a câmera do celular para avaliar sua visita</p>
      <img src="${imagem}" alt="QR de check-in" />
    </body></html>`);
    doc.close();
    // Nome entra como texto, não como HTML.
    doc.querySelector("h1").textContent = estab.nome || "";
    iframe.contentWindow.onafterprint = () => iframe.remove();
    setTimeout(() => iframe.contentWindow.print(), 100);
  };

  const gerarNovo = async () => {
    setGerando(true);
    try {
      const dados = await gerarNovoTokenCheckin(estab.idEstabelecimento);
      onTokenAlterado(dados.tokenCheckin);
      setConfirmando(false);
    } catch (e) {
      avisar(e.message || "Não foi possível gerar um novo QR.");
    } finally {
      setGerando(false);
    }
  };

  return (
    <section className="qr-checkin">
      <div className="qr-checkin-info">
        <h2 className="qr-checkin-titulo">QR de check-in</h2>
        <p className="qr-checkin-texto">
          Imprima e coloque nas mesas e no balcão. Quem ler com a câmera do celular
          confirma que esteve aqui e já cai na página de avaliação.
        </p>

        {semCoordenadas && (
          <p className="qr-checkin-alerta">
            Este estabelecimento ainda não tem localização no mapa, então o check-in
            pela localização do celular não vai funcionar. Por enquanto, só o QR confirma visitas.
          </p>
        )}

        {confirmando ? (
          <div className="qr-checkin-confirmacao">
            <p className="qr-checkin-alerta">
              Os QRs já impressos param de confirmar visitas na hora. Você vai precisar
              imprimir e trocar todos.
            </p>
            <div className="qr-checkin-acoes">
              <button type="button" className="adm-btn" onClick={() => setConfirmando(false)} disabled={gerando}>
                Cancelar
              </button>
              <button type="button" className="adm-btn qr-checkin-perigo" onClick={gerarNovo} disabled={gerando}>
                {gerando ? "Gerando..." : "Sim, gerar novo QR"}
              </button>
            </div>
          </div>
        ) : (
          <div className="qr-checkin-acoes">
            <button type="button" className="adm-btn adm-btn-principal" onClick={imprimir} disabled={!imagem}>
              Imprimir
            </button>
            <button type="button" className="adm-btn" onClick={() => setConfirmando(true)}>
              Gerar novo QR
            </button>
          </div>
        )}
      </div>

      <div className="qr-checkin-imagem">
        {imagem ? <img src={imagem} alt="QR de check-in" /> : <span>{token ? "Gerando QR..." : "QR indisponível"}</span>}
      </div>
    </section>
  );
}
