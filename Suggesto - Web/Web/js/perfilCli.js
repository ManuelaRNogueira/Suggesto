const API_BASE = window.API_BASE;
let usuarioAtual = null;
let fotoPreviewObjectUrl = null;

document.addEventListener("DOMContentLoaded", () => {
    iniciarEventos();
    carregarDadosUsuario();

    document.addEventListener("visibilitychange", () => {
        if (document.visibilityState === "visible") {
            const idUsuario = localStorage.getItem("idUsuario");
            if (idUsuario) carregarAtividadeRecente(idUsuario);
        }
    });
});

function iniciarEventos() {
    document.getElementById("btnSairSidebar")?.addEventListener("click", abrirModalSair);
    document.getElementById("btnConfirmarSaida")?.addEventListener("click", logout);

    document.querySelectorAll(".modal-fechar").forEach(btn => {
        btn.addEventListener("click", () => {
            btn.closest(".modal-fundo")?.classList.remove("aberto");
        });
    });

    document.querySelector(".botao-editar-perfil")?.addEventListener("click", () => abrirEdicao());
    document.getElementById("btnEditarFoto")?.addEventListener("click", () => abrirEdicao(true));
    document.getElementById("editFotoFile")?.addEventListener("change", atualizarPreviaFotoSelecionada);
    document.getElementById("btnRemoverFotoSelecionada")?.addEventListener("click", limparSelecaoFoto);

    document.querySelectorAll(".toggle").forEach(toggle => {
        toggle.addEventListener("click", (e) => toggleSwitch(toggle, e));
    });

    document.querySelectorAll(".menu-item").forEach(item => {
        item.addEventListener("click", () => {
            const acao = item.getAttribute("data-acao");
            if (acao) abrirSecao(acao);
        });
    });
}

function abrirModalSair() {
    document.getElementById("modalSaida")?.classList.add("aberto");
}

function abrirEdicao(selecionarFoto = false) {
    if (!usuarioAtual) {
        usuarioAtual = {
            nome: localStorage.getItem("nomeUsuario") || document.getElementById("heroNome")?.textContent || "",
            email: document.getElementById("heroEmail")?.textContent || "",
            fotoUrl: ""
        };
    }

    const editNome = document.getElementById("editNome");
    const editEmail = document.getElementById("editEmail");
    const editFotoFile = document.getElementById("editFotoFile");

    if (editNome) editNome.value = usuarioAtual.nome || "";
    if (editEmail) editEmail.value = usuarioAtual.email || "";
    if (editFotoFile) editFotoFile.value = "";
    liberarFotoPreviewTemporaria();
    restaurarPreviaFotoAtual();

    document.getElementById("modalEdicao")?.classList.add("aberto");

    if (selecionarFoto) {
        editFotoFile?.click();
    }
}

function fecharModal(id) {
    document.getElementById(id)?.classList.remove("aberto");
    if (id === "modalEdicao") {
        liberarFotoPreviewTemporaria();
    }
}

function logout() {
    localStorage.clear();
    window.location.href = "login.html";
}

async function carregarDadosUsuario() {
    const idUsuario = localStorage.getItem("idUsuario");

    if (!idUsuario) {
        window.location.href = "login.html";
        return;
    }

    try {
        const resposta = await fetch(`${API_BASE}/usuarios/${idUsuario}`);

        if (resposta.status === 404) {
            logout();
            return;
        }

        if (!resposta.ok) {
            throw new Error("Erro ao buscar dados do usuário.");
        }

        usuarioAtual = await resposta.json();
        preencherPerfil(usuarioAtual);
        await carregarAtividadeRecente(idUsuario);
        await carregarConquistas(idUsuario);

        if (usuarioAtual.nome) {
            localStorage.setItem("nomeUsuario", usuarioAtual.nome);
        }
    } catch (error) {
        console.error("Erro ao carregar perfil:", error);
        renderizarAtividadeVazia();
    }
}

// Complementa o que a API devolve (descrição, meta e progresso) com a unidade da
// contagem e uma dica de onde progredir. O requisito em si continua vindo do
// backend — aqui não se repete nenhum número, só orientação de navegação.
const FAMILIAS_CONQUISTA = {
    envio: {
        sing: "sugestão", plur: "sugestões",
        dica: "Vale qualquer sugestão enviada, em qualquer estabelecimento."
    },
    aprovada: {
        sing: "aprovação", plur: "aprovações",
        dica: "Conta quando o estabelecimento marca a sua sugestão como aprovada."
    },
    salvo: {
        sing: "local", plur: "locais",
        dica: "Salve estabelecimentos pelo botão de favorito na página deles. Eles ficam em Locais Salvos."
    },
    resgate: {
        sing: "recompensa", plur: "recompensas",
        dica: "Troque seus pontos por recompensas na página Pontos."
    },
    ponto: {
        sing: "ponto", plur: "pontos",
        dica: "Você acumula pontos enviando sugestões e tendo elas aprovadas."
    }
};

const FAMILIA_POR_CONQUISTA = {
    "pioneiro": "envio",
    "em-chamas": "envio",
    "veterano": "envio",
    "vencedor": "aprovada",
    "influente": "aprovada",
    "explorador": "salvo",
    "colecionador": "salvo",
    "primeiro-resgate": "resgate",
    "comprador": "resgate",
    "bronze": "ponto",
    "prata": "ponto",
    "ouro": "ponto",
    "platina": "ponto"
};

let conquistasCarregadas = [];

// Conquistas vêm calculadas do backend a partir do que o cliente realmente fez
// (sugestões, aprovações, locais salvos, resgates e nível).
async function carregarConquistas(idUsuario) {
    const grid = document.getElementById("conquistasGrid");
    const contador = document.getElementById("conquistasContador");
    if (!grid) return;

    try {
        const resposta = await fetch(`${API_BASE}/usuarios/${idUsuario}/conquistas`);
        if (!resposta.ok) throw new Error("Falha ao carregar conquistas.");

        const conquistas = await resposta.json();
        conquistasCarregadas = conquistas;
        const desbloqueadas = conquistas.filter((c) => c.desbloqueada).length;

        if (contador) contador.textContent = `${desbloqueadas} de ${conquistas.length}`;

        grid.innerHTML = conquistas
            .map((c) => {
                const classe = c.desbloqueada ? "conquista-desbloqueada" : "conquista-bloqueada";
                const dica = c.desbloqueada
                    ? c.descricao
                    : `${c.descricao} (${c.progresso}/${c.meta})`;
                return `
                    <div class="conquista-item ${classe}" title="${dica}" onclick="abrirConquista('${c.id}')">
                        <div class="conquista-icone"><i class="fas ${c.icone}"></i></div>
                        <span class="conquista-nome">${c.nome}</span>
                    </div>`;
            })
            .join("");
    } catch (error) {
        console.error("Erro ao carregar conquistas:", error);
        grid.innerHTML = `<p class="atividade-vazia">Não foi possível carregar as conquistas.</p>`;
    }
}

function abrirConquista(id) {
    const c = conquistasCarregadas.find((item) => item.id === id);
    if (!c) return;

    const familia = FAMILIAS_CONQUISTA[FAMILIA_POR_CONQUISTA[c.id]] || FAMILIAS_CONQUISTA.envio;
    const meta = Number(c.meta) || 0;
    const progresso = Number(c.progresso) || 0;
    const faltam = Math.max(0, meta - progresso);

    document.getElementById("conquistaTitulo").textContent = c.nome;
    document.getElementById("conquistaDescricao").textContent = c.descricao;
    document.getElementById("conquistaDica").textContent = familia.dica;
    document.getElementById("conquistaIcone").innerHTML = `<i class="fas ${c.icone}"></i>`;

    // As cores do ícone vêm das mesmas regras da grade, então o estado precisa
    // estar num ancestral dele.
    document.getElementById("conquistaDetalhe").className =
        "conquista-detalhe " + (c.desbloqueada ? "conquista-desbloqueada" : "conquista-bloqueada");

    const selo = document.getElementById("conquistaSelo");
    selo.textContent = c.desbloqueada ? "Desbloqueada" : "Bloqueada";
    selo.className = "conquista-selo " + (c.desbloqueada ? "conquista-selo-ok" : "conquista-selo-bloq");

    // Barra só faz sentido em conquista de acúmulo. Nas de passo único (meta 1)
    // e no Bronze (meta 0) ela não diria nada além do selo.
    const bloco = document.getElementById("conquistaProgresso");
    const faltamTexto = document.getElementById("conquistaFaltam");

    if (meta > 1) {
        const pct = Math.min(100, Math.round((progresso / meta) * 100));
        document.getElementById("conquistaContagem").textContent = `${progresso} de ${meta}`;
        document.getElementById("conquistaPercentual").textContent = `${pct}%`;
        document.getElementById("conquistaBarra").style.width = `${pct}%`;

        if (c.desbloqueada) {
            faltamTexto.style.display = "none";
        } else {
            faltamTexto.textContent = faltam === 1
                ? `Falta 1 ${familia.sing}`
                : `Faltam ${faltam} ${familia.plur}`;
            faltamTexto.style.display = "";
        }
        bloco.style.display = "";
    } else {
        bloco.style.display = "none";
    }

    document.getElementById("modalConquista").classList.add("aberto");
}

function preencherPerfil(usuario) {
    const nome = usuario.nome || "Usuário";
    const email = usuario.email || "";
    const fotoUrl = resolverUrlFoto(usuario.fotoUrl);
    const iniciais = gerarIniciais(nome);
    const totalSalvos = Number(usuario.totalLocaisSalvos) || 0;
    const totalSugestoes = Number(usuario.totalSugestoes) || 0;
    const pontos = Number(usuario.pontos) || 0;

    setTexto("sidebarNome", nome);
    setTexto("sidebarAvatar", iniciais);
    setTexto("heroNome", nome);
    setTexto("heroEmail", email);

    // O selo do topo mostra o nível conquistado por pontos (Bronze/Prata/Ouro/
    // Platina) — antes mostrava o plano, que é coisa de administrador.
    const heroPlanoWrap = document.getElementById("heroPlanoWrap");
    const heroPlanoNome = document.getElementById("heroPlanoNome");
    const heroBadge = document.getElementById("heroPlano");
    const nivelAtual = calcularNivel(pontos).atual;
    if (heroPlanoWrap && heroPlanoNome) {
        heroPlanoNome.textContent = nivelAtual.nome;
        if (heroBadge) heroBadge.className = `nivel-badge ${classeNivel(nivelAtual.id)}`;
        heroPlanoWrap.style.display = "";
    }

    atualizarAvatar(fotoUrl, iniciais);

    setTexto("totalSalvos",
        `${totalSalvos} estabelecimento${totalSalvos !== 1 ? "s" : ""} favorito${totalSalvos !== 1 ? "s" : ""}`);
    setTexto("totalSugestoes",
        `${totalSugestoes} sugest${totalSugestoes !== 1 ? "ões" : "ão"} enviada${totalSugestoes !== 1 ? "s" : ""}`);
    setTexto("statSalvos", totalSalvos);
    setTexto("statSugestoes", totalSugestoes);
    setTexto("statPontos", formatarPontos(pontos));

    aplicarNivelPerfil(pontos);
}

async function carregarAtividadeRecente(idUsuario) {
    const container = document.getElementById("atividadeLista");
    if (!container) return;

    try {
        const resposta = await fetch(`${API_BASE}/avaliacoes/usuario/${idUsuario}`);
        if (!resposta.ok) throw new Error("Falha ao carregar atividade.");

        const avaliacoes = await resposta.json();
        const aprovadas = avaliacoes.filter((item) => isStatusAprovado(item.status)).length;
        setTexto("statAprovadas", aprovadas);

        const ordenadas = [...avaliacoes].sort((a, b) => {
            const dataA = new Date(a.dataAvaliacao || 0).getTime();
            const dataB = new Date(b.dataAvaliacao || 0).getTime();
            return dataB - dataA;
        });

        const recentes = ordenadas.slice(0, 5);

        if (!recentes.length) {
            renderizarAtividadeVazia();
            return;
        }

        container.innerHTML = recentes.map(montarItemAtividade).join("");
    } catch (error) {
        console.error("Erro ao carregar atividade:", error);
        setTexto("statAprovadas", 0);
        renderizarAtividadeVazia();
    }
}

function montarItemAtividade(avaliacao) {
    const statusChave = chaveStatus(avaliacao.status);
    const nomeLoja = avaliacao.estabelecimento?.nome || "Estabelecimento";
    const categoria = rotuloCategoriaAvaliacao(avaliacao);
    const dataRelativa = formatarDataRelativa(avaliacao.dataAvaliacao);

    let titulo = "Sugestão enviada";
    if (statusChave === "aceita") titulo = "Sugestão aprovada";
    if (statusChave === "recusada") titulo = "Sugestão recusada";

    return `
        <div class="atividade-item">
            <div class="atividade-info">
                <p class="atividade-titulo">${titulo}</p>
                <p class="atividade-sub">${nomeLoja} · ${categoria}</p>
            </div>
            <div class="atividade-data">${dataRelativa}</div>
        </div>`;
}

function renderizarAtividadeVazia() {
    const container = document.getElementById("atividadeLista");
    if (container) {
        container.innerHTML = `<p class="atividade-vazia">Nenhuma atividade recente registrada.</p>`;
    }
}

function formatarDataRelativa(dataIso) {
    if (!dataIso) return "—";

    const data = new Date(dataIso);
    if (Number.isNaN(data.getTime())) return "—";

    const diffMs = Date.now() - data.getTime();
    const diffDias = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDias <= 0) return "hoje";
    if (diffDias === 1) return "há 1 dia";
    if (diffDias < 7) return `há ${diffDias} dias`;
    if (diffDias < 30) {
        const semanas = Math.floor(diffDias / 7);
        return semanas === 1 ? "há 1 sem." : `há ${semanas} sem.`;
    }

    return data.toLocaleDateString("pt-BR", {
        day: "2-digit",
        month: "short",
        year: "numeric"
    });
}

function aplicarNivelPerfil(pontos) {
    const prog = calcularProgressoNivel(pontos);

    const cardNivel = document.querySelector(".card-nivel");
    if (cardNivel) cardNivel.dataset.nivel = prog.atual.id;

    const desc = document.getElementById("perfilNivelDesc");
    if (desc) {
        desc.textContent = prog.proximo
            ? `Próximo nível: ${prog.proximo.nome} (Faltam ${formatarPontos(prog.faltaParaProximo)} pts)`
            : `Nível máximo: ${prog.atual.nome}`;
    }

    const badge = document.getElementById("perfilBadgeNivel");
    const badgeTexto = document.getElementById("perfilBadgeTexto");
    if (badge) {
        badge.className = `nivel-badge-grande ${classeNivel(prog.atual.id)}`;
    }
    if (badgeTexto) badgeTexto.textContent = prog.atual.nome;

    setTexto("labelNivelAtual", prog.atual.nome);
    setTexto(
        "labelPontosProgresso",
        prog.proximo
            ? `${formatarPontos(prog.pontosNoNivel)} / ${formatarPontos(prog.pontosParaProximo)} pts`
            : `${formatarPontos(pontos)} pts`
    );
    setTexto("labelProximoNivel", prog.proximo ? prog.proximo.nome : "Máximo");

    const barra = document.getElementById("perfilBarraFill");
    if (barra) barra.style.width = `${prog.percentual}%`;

    const faltam = document.getElementById("perfilFaltamPontos");
    if (faltam) {
        faltam.innerHTML = prog.proximo
            ? `<i class="fas fa-bolt"></i> Faltam ${formatarPontos(prog.faltaParaProximo)} pontos para ${prog.proximo.nome}`
            : `<i class="fas fa-crown"></i> Nível máximo alcançado`;
    }

    const tituloBenef = document.getElementById("perfilBeneficiosTitulo");
    if (tituloBenef) tituloBenef.textContent = `Benefícios ${prog.atual.nome}`;

    const lista = document.getElementById("perfilBeneficiosLista");
    if (lista) {
        lista.innerHTML = beneficiosPorNivel(prog.atual.id)
            .map(
                (b) => `
              <div class="beneficio-item">
                <i class="fas fa-check-circle"></i>
                <span>${b}</span>
              </div>`
            )
            .join("");
    }
}

function setTexto(id, valor) {
    const el = document.getElementById(id);
    if (el) el.textContent = valor;
}

function atualizarAvatar(fotoUrl, iniciais) {
    const img = document.getElementById("avatarImg");
    const iniciaisEl = document.getElementById("avatarIniciais");

    if (!img || !iniciaisEl) return;

    const urlFoto = resolverUrlFoto(fotoUrl);

    if (urlFoto) {
        img.src = urlFoto;
        img.style.display = "block";
        iniciaisEl.style.display = "none";
        iniciaisEl.textContent = iniciais;
    } else {
        img.removeAttribute("src");
        img.style.display = "none";
        iniciaisEl.style.display = "flex";
        iniciaisEl.textContent = iniciais;
    }
}

function resolverUrlFoto(fotoUrl) {
    if (!fotoUrl) return "";

    if (fotoUrl.startsWith("http://") || fotoUrl.startsWith("https://")) {
        return fotoUrl;
    }

    if (fotoUrl.startsWith("/uploads/")) {
        return `${window.API_ORIGIN}${fotoUrl}`;
    }

    return `${window.API_ORIGIN}/uploads/${fotoUrl}`;
}

function atualizarPreviaFotoSelecionada(event) {
    const input = event.currentTarget;
    const arquivo = input.files?.[0];
    if (!arquivo) {
        restaurarPreviaFotoAtual();
        return;
    }

    const erro = validarArquivoFoto(arquivo);
    if (erro) {
        input.value = "";
        restaurarPreviaFotoAtual();
        mostrarToast(erro);
        return;
    }

    liberarFotoPreviewTemporaria();
    fotoPreviewObjectUrl = URL.createObjectURL(arquivo);
    exibirPreviaFoto(fotoPreviewObjectUrl, gerarIniciais(usuarioAtual?.nome));

    setTexto("fotoSeletorTitulo", "Foto pronta para salvar");
    setTexto("fotoSeletorAcao", "Trocar foto");
    setTexto("fotoArquivoNome", arquivo.name);
    setTexto("fotoArquivoTamanho", formatarTamanhoArquivo(arquivo.size));

    const arquivoInfo = document.getElementById("fotoArquivo");
    if (arquivoInfo) arquivoInfo.hidden = false;
}

function validarArquivoFoto(arquivo) {
    const tiposPermitidos = ["image/jpeg", "image/png", "image/gif", "image/webp"];

    if (!tiposPermitidos.includes(arquivo.type.toLowerCase())) {
        return "Use uma imagem JPG, PNG, GIF ou WebP.";
    }
    if (arquivo.size > 5 * 1024 * 1024) {
        return "A imagem deve ter no máximo 5 MB.";
    }
    return "";
}

function limparSelecaoFoto() {
    const input = document.getElementById("editFotoFile");
    if (input) input.value = "";
    liberarFotoPreviewTemporaria();
    restaurarPreviaFotoAtual();
}

function restaurarPreviaFotoAtual() {
    const fotoAtual = resolverUrlFoto(usuarioAtual?.fotoUrl);
    exibirPreviaFoto(fotoAtual, gerarIniciais(usuarioAtual?.nome));
    setTexto("fotoSeletorTitulo", fotoAtual ? "Trocar foto de perfil" : "Escolher uma foto");
    setTexto("fotoSeletorAcao", fotoAtual ? "Trocar foto" : "Selecionar");

    const arquivoInfo = document.getElementById("fotoArquivo");
    if (arquivoInfo) arquivoInfo.hidden = true;
}

function exibirPreviaFoto(fotoUrl, iniciais) {
    const img = document.getElementById("editFotoPreview");
    const iniciaisEl = document.getElementById("editFotoIniciais");
    if (!img || !iniciaisEl) return;

    if (fotoUrl) {
        img.src = fotoUrl;
        img.hidden = false;
        iniciaisEl.hidden = true;
    } else {
        img.removeAttribute("src");
        img.hidden = true;
        iniciaisEl.hidden = false;
        iniciaisEl.textContent = iniciais || "??";
    }
}

function liberarFotoPreviewTemporaria() {
    if (!fotoPreviewObjectUrl) return;
    URL.revokeObjectURL(fotoPreviewObjectUrl);
    fotoPreviewObjectUrl = null;
}

function formatarTamanhoArquivo(bytes) {
    if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1).replace(".", ",")} MB`;
}

async function salvarEdicao() {
    const idUsuario = localStorage.getItem("idUsuario");
    if (!idUsuario) {
        window.location.href = "login.html";
        return;
    }

    const formData = new FormData();
    formData.append("nome", document.getElementById("editNome")?.value?.trim() || "");

    const arquivoFoto = document.getElementById("editFotoFile")?.files?.[0];
    if (arquivoFoto) {
        const erroFoto = validarArquivoFoto(arquivoFoto);
        if (erroFoto) {
            mostrarToast(erroFoto);
            return;
        }
        formData.append("foto", arquivoFoto);
    }

    try {
        const resposta = await fetch(`${API_BASE}/usuarios/${idUsuario}`, {
            method: "PUT",
            body: formData
        });

        if (!resposta.ok) {
            const erro = await resposta.json();
            throw new Error(erro.message || "Erro ao salvar perfil.");
        }

        usuarioAtual = await resposta.json();
        preencherPerfil(usuarioAtual);
        await carregarAtividadeRecente(idUsuario);

        if (usuarioAtual.nome) {
            localStorage.setItem("nomeUsuario", usuarioAtual.nome);
        }

        fecharModal("modalEdicao");
        liberarFotoPreviewTemporaria();
        mostrarToast("Perfil atualizado com sucesso!");
    } catch (error) {
        console.error("Erro ao salvar perfil:", error);
        mostrarToast(error.message || "Não foi possível salvar o perfil.");
    }
}

function gerarIniciais(nome) {
    if (!nome || !nome.trim()) return "??";

    return nome
        .trim()
        .split(/\s+/)
        .map(parte => parte[0])
        .join("")
        .substring(0, 2)
        .toUpperCase();
}

function mostrarToast(msg) {
    const toast = document.getElementById("toast");
    const texto = document.getElementById("toastMsg");

    if (!toast || !texto) return;

    texto.textContent = msg;
    toast.classList.add("ativo");

    setTimeout(() => {
        toast.classList.remove("ativo");
    }, 3000);
}

function toggleSwitch(element, event) {
    event.stopPropagation();
    element.classList.toggle("ativo");
}

function abrirSecao(secao) {
    const rotas = {
        "locais-salvos": "locaisSalvosCli.html",
        "minhas-sugestoes": "sugestoesCli.html",
        "historico": "lojapontosCli.html#historico",
        "notificacoes": "#",
        "privacidade": "#"
    };

    if (rotas[secao]) {
        window.location.href = rotas[secao];
    }
}
