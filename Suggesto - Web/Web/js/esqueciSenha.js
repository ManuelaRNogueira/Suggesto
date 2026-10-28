// Tela "Esqueci minha senha": manda o e-mail pra API, que envia o link de redefinição.

const formEsqueci = document.getElementById('formEsqueci');
const emailInput = document.getElementById('email');
const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

function mostrarErro(mensagem) {
    toastMsgErro.textContent = mensagem;
    toastErro.classList.add('visivel');

    setTimeout(() => {
        toastErro.classList.remove('visivel');
    }, 3500);
}

emailInput.addEventListener('input', () => emailInput.classList.remove('input-erro'));

// A API responde a mesma coisa exista a conta ou não (pra ninguém descobrir
// quais e-mails estão cadastrados), então a tela também mostra sempre o mesmo aviso.
formEsqueci.addEventListener('submit', async (evento) => {
    evento.preventDefault();

    const email = emailInput.value.trim();
    if (!email || !email.includes("@") || !email.includes(".")) {
        emailInput.classList.add('input-erro');
        mostrarErro("Digite um endereço de e-mail válido.");
        return;
    }

    const botao = formEsqueci.querySelector('button');
    const textoOriginal = botao.innerText;
    botao.innerText = "Enviando...";
    botao.disabled = true;

    try {
        const resposta = await fetch(`${window.API_BASE}/senha/esqueci`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email })
        });
        const resultado = await resposta.json();

        if (resposta.ok && resultado.success) {
            document.getElementById('textoEnviado').textContent = resultado.message;
            document.getElementById('subtitulo').hidden = true;
            formEsqueci.hidden = true;
            document.getElementById('mensagemEnviado').hidden = false;
            return;
        }

        mostrarErro(resultado.message || "Não foi possível enviar o link. Tente de novo.");
    } catch (error) {
        console.error("Erro na requisição:", error);
        mostrarErro("Servidor offline. Verifique se a API está rodando.");
    }

    botao.innerText = textoOriginal;
    botao.disabled = false;
});
