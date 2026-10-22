const formRedefinir = document.getElementById('formRedefinir');
const senhaInput = document.getElementById('senha');
const confirmarInput = document.getElementById('confirmarSenha');
const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

// Chega pelo link do e-mail: redefinir-senha.html?token=...
const token = new URLSearchParams(window.location.search).get('token');

function mostrarErro(mensagem) {
    toastMsgErro.textContent = mensagem;
    toastErro.classList.add('visivel');

    setTimeout(() => {
        toastErro.classList.remove('visivel');
    }, 3500);
}

function mostrarEstado(idMensagem, titulo) {
    formRedefinir.hidden = true;
    document.getElementById('titulo').textContent = titulo;
    document.getElementById(idMensagem).hidden = false;
}

if (!token) {
    mostrarEstado('mensagemInvalido', "Link inválido");
}

senhaInput.addEventListener('input', () => senhaInput.classList.remove('input-erro'));
confirmarInput.addEventListener('input', () => confirmarInput.classList.remove('input-erro'));

formRedefinir.addEventListener('submit', async (evento) => {
    evento.preventDefault();

    const erroSenha = validarSenhaForte(senhaInput.value);
    if (erroSenha) {
        senhaInput.classList.add('input-erro');
        mostrarErro(erroSenha);
        return;
    }

    if (senhaInput.value !== confirmarInput.value) {
        senhaInput.classList.add('input-erro');
        confirmarInput.classList.add('input-erro');
        mostrarErro("As senhas não coincidem.");
        return;
    }

    const botao = formRedefinir.querySelector('button');
    const textoOriginal = botao.innerText;
    botao.innerText = "Salvando...";
    botao.disabled = true;

    try {
        const resposta = await fetch(`${window.API_BASE}/senha/redefinir`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ token, senha: senhaInput.value.trim() })
        });
        const resultado = await resposta.json();

        if (resposta.ok && resultado.success) {
            mostrarEstado('mensagemSucesso', "Senha alterada");
            return;
        }

        if (resultado.tokenInvalido) {
            mostrarEstado('mensagemInvalido', "Link inválido");
            return;
        }

        senhaInput.classList.add('input-erro');
        mostrarErro(resultado.message || "Não foi possível alterar a senha. Tente de novo.");
    } catch (error) {
        console.error("Erro na requisição:", error);
        mostrarErro("Servidor offline. Verifique se a API está rodando.");
    }

    botao.innerText = textoOriginal;
    botao.disabled = false;
});
