// Card de estabelecimento — componente único usado em inicioCli.html e
// locaisSalvosCli.html (antes cada página tinha sua própria cópia, com
// pequenas divergências que causavam bugs: nota fixa em "5.0" e endereço
// quebrado em Locais Salvos). Carregado antes do script de cada página, que
// só passa as opções específicas (estado de favorito, callbacks de clique).
//
// Depende de calcularStatusEstabelecimento (ver js/horarioUtils.js) e de
// slugCategoriaEstabelecimento (ver js/avaliacoesUtils.js), já carregados
// nas duas páginas antes deste arquivo.

const PLACEHOLDER_ESTABELECIMENTO = "imagens/placeholder-local.png";

function obterIdEstabelecimento(estab) {
  const candidatos = [estab?.idEstabelecimento, estab?.id_estabelecimento, estab?.id];

  for (const valor of candidatos) {
    const id = Number(valor);
    if (Number.isFinite(id) && id > 0) return id;
  }

  return null;
}

function urlFotoEstabelecimento(fotoPath) {
  const nome = fotoPath ? String(fotoPath).trim() : "";
  if (!nome) return PLACEHOLDER_ESTABELECIMENTO;
  if (nome.startsWith("http://") || nome.startsWith("https://")) return nome;
  const relativo = nome.replace(/^uploads\//, "");
  return `${window.API_ORIGIN}/uploads/${relativo}`;
}

function formatarMediaEstabelecimento(estab) {
  const candidatos = [estab?.mediaAvaliacoes, estab?.mediaAvaliacao, estab?.notaMedia, estab?.nota];

  for (const valor of candidatos) {
    const num = Number(valor);
    if (Number.isFinite(num) && num > 0) return num.toFixed(1);
  }

  return "N/A";
}

// Estabelecimento não tem um campo "endereco" pronto — monta a partir de
// rua/numero/bairro/cidade/estado, igual ao resto do site.
function montarEnderecoCard(estab) {
  if (!estab.rua) return "Endereço não informado";
  const bairro = estab.bairro ? ` - ${estab.bairro}` : "";
  return `${estab.rua}, ${estab.numero}${bairro} (${estab.cidade}/${estab.estado})`;
}

const SVG_SALVAR_OFF =
  '<svg class="salvar-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" /></svg>';
const SVG_SALVAR_ON =
  '<svg class="salvar-icon" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="1.8"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" /></svg>';

function criarBotaoFavorito(idEstab, jaSalvo, aoClicar) {
  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = `local-favorito${jaSalvo ? " salvo" : ""}`;
  btn.title = jaSalvo ? "Remover dos salvos" : "Salvar local";
  btn.innerHTML = jaSalvo ? SVG_SALVAR_ON : SVG_SALVAR_OFF;

  btn.addEventListener("click", (event) => {
    event.stopPropagation();
    aoClicar(idEstab, btn);
  });

  return btn;
}

function atualizarIconeFavorito(btn, salvo) {
  btn.classList.toggle("salvo", salvo);
  btn.innerHTML = salvo ? SVG_SALVAR_ON : SVG_SALVAR_OFF;
  btn.title = salvo ? "Remover dos salvos" : "Salvar local";
}

function formatarDistanciaCard(km) {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1).replace(".", ",")} km`;
}

// opcoes:
//   verificarSalvo(idEstab) -> bool   (padrão: sempre não-salvo)
//   aoClicarFavorito(idEstab, btn)    (se omitido, o botão de favorito não aparece)
//   aoClicarSugerir(idEstab, nome)    (padrão: navega pra fazerSugestao.html)
//   aoClicarImagem(idEstab)           (padrão: navega pra estabelecimentoCli.html)
//   distanciaKm                       (número opcional — some ao endereço, ex: "· 1,2 km")
function criarCardEstabelecimento(estab, opcoes = {}) {
  const card = document.createElement("div");
  card.className = "local-card";

  // Slug oficial (ver CATEGORIAS_OFICIAIS em avaliacoesUtils.js) — não o
  // texto cru, que varia de acentuação/barra e não bate com os filtros.
  card.dataset.categoria = slugCategoriaEstabelecimento(estab.categoria);

  const nomeCerto = estab.nome || "Nome Indisponível";
  card.dataset.nome = nomeCerto;

  const idCerto = obterIdEstabelecimento(estab);
  if (idCerto) card.dataset.estabelecimentoId = String(idCerto);

  const jaSalvo = opcoes.verificarSalvo ? !!opcoes.verificarSalvo(idCerto) : false;
  const imagemURL = urlFotoEstabelecimento(estab.fotoPath);

  const imagemDiv = document.createElement("div");
  imagemDiv.className = "local-imagem";

  const imgFoto = document.createElement("img");
  imgFoto.className = "local-foto";
  imgFoto.alt = nomeCerto;
  imgFoto.src = imagemURL;
  imgFoto.onerror = function () {
    this.onerror = null;
    this.src = PLACEHOLDER_ESTABELECIMENTO;
  };
  imagemDiv.appendChild(imgFoto);

  if (idCerto) {
    imagemDiv.style.cursor = "pointer";
    imagemDiv.addEventListener("click", () => {
      if (opcoes.aoClicarImagem) {
        opcoes.aoClicarImagem(idCerto);
      } else {
        window.location.href = `estabelecimentoCli.html?id=${idCerto}`;
      }
    });
  }

  const categoriaSpan = document.createElement("span");
  categoriaSpan.className = "local-categoria";
  categoriaSpan.textContent = estab.categoria || "Local";
  imagemDiv.appendChild(categoriaSpan);

  if (opcoes.aoClicarFavorito) {
    imagemDiv.appendChild(criarBotaoFavorito(idCerto, jaSalvo, opcoes.aoClicarFavorito));
  }

  const status = calcularStatusEstabelecimento(estab.horarioFuncionamento);
  if (status.disponivel) {
    const statusSpan = document.createElement("span");
    statusSpan.className = `local-status ${status.aberto ? "aberto" : "fechado"}`;
    statusSpan.innerHTML = `<span class="local-status-dot"></span>${status.label}`;
    imagemDiv.appendChild(statusSpan);
  }

  const infoDiv = document.createElement("div");
  infoDiv.className = "local-info";

  const topoDiv = document.createElement("div");
  topoDiv.className = "local-info-topo";

  const nomeContainer = document.createElement("div");

  const nomeEl = document.createElement("h3");
  nomeEl.className = "local-nome";
  nomeEl.textContent = nomeCerto;

  const enderecoEl = document.createElement("p");
  enderecoEl.className = "local-endereco";
  let enderecoTexto = montarEnderecoCard(estab);
  if (typeof opcoes.distanciaKm === "number") {
    enderecoTexto += ` · ${formatarDistanciaCard(opcoes.distanciaKm)}`;
  }
  enderecoEl.innerHTML = `<i class="fas fa-map-marker-alt"></i> ${enderecoTexto}`;

  nomeContainer.appendChild(nomeEl);
  nomeContainer.appendChild(enderecoEl);

  const notaDiv = document.createElement("div");
  notaDiv.className = "local-nota";
  notaDiv.innerHTML = `
            <i class="fas fa-star"></i>
            <span>${formatarMediaEstabelecimento(estab)}</span>
        `;

  topoDiv.appendChild(nomeContainer);
  topoDiv.appendChild(notaDiv);

  const rodapeDiv = document.createElement("div");
  rodapeDiv.className = "local-rodape";

  const tagSpan = document.createElement("span");
  tagSpan.className = "local-tag";
  tagSpan.textContent = `#${estab.categoria || "Sugestão"}`;

  const botao = document.createElement("button");
  botao.className = "local-btn-sugestao";
  botao.innerHTML = `<i class="fas fa-comment-alt"></i> Sugerir`;

  botao.addEventListener("click", (event) => {
    event.stopPropagation();
    if (opcoes.aoClicarSugerir) {
      opcoes.aoClicarSugerir(idCerto, nomeCerto);
    } else {
      window.location.href = `./fazerSugestao.html?id=${idCerto}&nome=${encodeURIComponent(nomeCerto)}`;
    }
  });

  rodapeDiv.appendChild(tagSpan);
  rodapeDiv.appendChild(botao);

  infoDiv.appendChild(topoDiv);
  infoDiv.appendChild(rodapeDiv);

  card.appendChild(imagemDiv);
  card.appendChild(infoDiv);

  return card;
}
