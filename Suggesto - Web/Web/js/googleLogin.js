// "Entrar com Google" (Google Identity Services, botão oficial) usado no login
// e no cadastro do cliente. O ID token recebido do Google vai para a API, que
// valida e devolve a mesma resposta do login por e-mail e senha.
// Precisa de config.js antes; o script do Google chama renderizarBotaoGoogle
// quando termina de carregar.

let configGoogle = null;

// opcoes: { containerId, texto: "signin_with" | "signup_with", mostrarErro(msg) }
function configurarLoginGoogle(opcoes) {
    configGoogle = opcoes;
    renderizarBotaoGoogle();
}

function renderizarBotaoGoogle() {
    if (!configGoogle || !window.google?.accounts?.id) return;

    const container = document.getElementById(configGoogle.containerId);
    if (!container) return;

    // O bloco (com o divisor "ou") só aparece quando o botão existe de fato,
    // para não sobrar um "ou" solto se o script do Google não carregar.
    const bloco = container.closest(".login-google");
    if (bloco) bloco.hidden = false;

    google.accounts.id.initialize({
        client_id: window.GOOGLE_CLIENT_ID,
        callback: receberCredencialGoogle,
    });

    google.accounts.id.renderButton(container, {
        theme: "filled_black",
        size: "large",
        shape: "pill",
        text: configGoogle.texto || "signin_with",
        locale: "pt-BR",
        width: Math.min(container.offsetWidth || 300, 400),
    });
}

async function receberCredencialGoogle(resposta) {
    try {
        const respostaApi = await fetch(`${window.API_BASE}/login/google`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ credential: resposta.credential }),
        });

        const resultado = await respostaApi.json();

        if (respostaApi.ok && resultado.success) {
            salvarSessaoLogin(resultado, resultado.email);
            if (resultado.perfilIncompleto) {
                localStorage.setItem("avisoCompletarPerfil", "1");
            }
            window.location.href = paginaInicialPorTipo(resultado.tipoUsuario);
        } else {
            configGoogle.mostrarErro(resultado.message || "Não foi possível entrar com o Google.");
        }
    } catch (error) {
        console.error("Erro no login com Google:", error);
        configGoogle.mostrarErro("Servidor offline. Verifique se a API está rodando.");
    }
}

// Mesmo armazenamento de sessão para os dois tipos de login.
function salvarSessaoLogin(resultado, email) {
    localStorage.setItem("idUsuario", resultado.idUsuario);
    localStorage.setItem("nomeUsuario", resultado.nome);
    localStorage.setItem("tipoUsuario", resultado.tipoUsuario);
    localStorage.setItem("emailUsuario", email);
    localStorage.removeItem("avisoCompletarPerfil");
}

function paginaInicialPorTipo(tipoUsuario) {
    // O Java manda exatamente a string do Enum (ex: "Administrador" ou "Cliente")
    return tipoUsuario === "Administrador" ? "inicioAdm.html" : "inicioCli.html";
}
