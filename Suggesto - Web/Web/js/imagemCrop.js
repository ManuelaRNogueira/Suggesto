// Modal de recorte de imagem — usado no upload de foto de perfil (perfilCli.js)
// e de estabelecimento (cadastroAdm.js). Sempre corta em quadrado (1:1), que é
// como a foto aparece em todo o site (avatar circular, logo de estabelecimento,
// cards de local/recompensa — todos square + object-fit: cover).
//
// Uso: const recortado = await abrirRecorteImagem(arquivoOriginal);
// Resolve com um novo File (já recortado) ou null se o usuário cancelar.
//
// Depende do Cropper.js (carregado via CDN nas páginas que usam isso).

function abrirRecorteImagem(arquivo) {
  return new Promise((resolve) => {
    const urlOriginal = URL.createObjectURL(arquivo);
    let finalizado = false;

    const overlay = document.createElement("div");
    overlay.className = "recorte-overlay";
    overlay.innerHTML = `
      <div class="recorte-modal">
        <div class="recorte-topo">
          <h3>Ajustar foto</h3>
          <button type="button" class="recorte-fechar" aria-label="Cancelar">&times;</button>
        </div>
        <div class="recorte-area">
          <img class="recorte-imagem" src="${urlOriginal}" alt="Foto a recortar">
        </div>
        <div class="recorte-zoom">
          <i class="fas fa-search-minus"></i>
          <input type="range" class="recorte-zoom-slider" min="0" max="3" step="0.01" value="0">
          <i class="fas fa-search-plus"></i>
        </div>
        <div class="recorte-acoes">
          <button type="button" class="recorte-btn recorte-btn-cancelar">Cancelar</button>
          <button type="button" class="recorte-btn recorte-btn-confirmar">Usar foto</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    const imgEl = overlay.querySelector(".recorte-imagem");
    const zoomSlider = overlay.querySelector(".recorte-zoom-slider");
    let cropper;

    function finalizar(resultado) {
      if (finalizado) return;
      finalizado = true;
      if (cropper) cropper.destroy();
      overlay.remove();
      URL.revokeObjectURL(urlOriginal);
      resolve(resultado);
    }

    imgEl.addEventListener("load", () => {
      cropper = new Cropper(imgEl, {
        aspectRatio: 1,
        viewMode: 1,
        dragMode: "move",
        autoCropArea: 1,
        background: false,
        zoom(evento) {
          zoomSlider.value = evento.detail.ratio;
        },
      });
    });

    zoomSlider.addEventListener("input", () => {
      if (cropper) cropper.zoomTo(Number(zoomSlider.value));
    });

    overlay.querySelector(".recorte-fechar").addEventListener("click", () => finalizar(null));
    overlay.querySelector(".recorte-btn-cancelar").addEventListener("click", () => finalizar(null));
    overlay.addEventListener("click", (evento) => {
      if (evento.target === overlay) finalizar(null);
    });

    overlay.querySelector(".recorte-btn-confirmar").addEventListener("click", () => {
      if (!cropper) return;
      cropper.getCroppedCanvas({ width: 1000, height: 1000, imageSmoothingQuality: "high" }).toBlob((blob) => {
        if (!blob) {
          finalizar(null);
          return;
        }
        const arquivoRecortado = new File([blob], arquivo.name, { type: blob.type || arquivo.type });
        finalizar(arquivoRecortado);
      }, arquivo.type && arquivo.type !== "image/gif" ? arquivo.type : "image/png");
    });
  });
}
