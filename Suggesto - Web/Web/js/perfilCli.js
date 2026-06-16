const API_BASE = "http://localhost:8080/api";
let usuarioAtual = null;

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

    document.querySelector(".botao-editar-perfil")?.addEventListener("click", abrirEdicao);

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

function abrirEdicao() {
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

    document.getElementById("modalEdicao")?.classList.add("aberto");
}

function fecharModal(id) {
    document.getElementById(id)?.classList.remove("aberto");
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

        if (usuarioAtual.nome) {
            localStorage.setItem("nomeUsuario", usuarioAtual.nome);
        }
    } catch (error) {
        console.error("Erro ao carregar perfil:", error);
        renderizarAtividadeVazia();
    }
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

    const heroPlanoWrap = document.getElementById("heroPlanoWrap");
    const heroPlanoNome = document.getElementById("heroPlanoNome");
    if (usuario.nomePlano && heroPlanoWrap && heroPlanoNome) {
        heroPlanoNome.textContent = usuario.nomePlano;
        heroPlanoWrap.style.display = "";
    } else if (heroPlanoWrap) {
        heroPlanoWrap.style.display = "none";
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
        return `http://localhost:8080${fotoUrl}`;
    }

    return `http://localhost:8080/uploads/${fotoUrl}`;
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
        if (!arquivoFoto.type.startsWith("image/")) {
            mostrarToast("Selecione um arquivo de imagem válido.");
            return;
        }
        if (arquivoFoto.size > 5 * 1024 * 1024) {
            mostrarToast("A imagem deve ter no máximo 5 MB.");
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
        "contribuicao": "#",
        "historico": "#",
        "notificacoes": "#",
        "privacidade": "#"
    };

    if (rotas[secao]) {
        window.location.href = rotas[secao];
    }
}
