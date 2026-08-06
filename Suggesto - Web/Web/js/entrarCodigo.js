const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

const idUsuario = localStorage.getItem('idUsuario');

if (!idUsuario) {
    window.location.href = 'entrarEquipe.html';
}

function mostrarMensagem(mensagem) {
    toastMsgErro.textContent = mensagem;
    toastErro.classList.add('visivel');

    setTimeout(() => {
        toastErro.classList.remove('visivel');
    }, 3500);
}

const codigoInput = document.getElementById('codigo');

codigoInput.addEventListener('input', () => {
    codigoInput.value = codigoInput.value.toUpperCase();
    codigoInput.classList.remove('input-erro');
});

async function entrarNaEquipe() {
    const codigo = codigoInput.value.trim();

    if (!codigo) {
        codigoInput.classList.add('input-erro');
        mostrarMensagem('Digite o código do estabelecimento.');
        return;
    }

    const botao = document.querySelector('#formCodigo .botao-principal');
    const textoOriginal = botao.innerText;

    botao.innerText = 'Verificando...';
    botao.disabled = true;

    try {
        const resposta = await fetch('http://localhost:8080/api/estabelecimentos/entrar', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ usuarioId: idUsuario, codigo })
        });

        const resultado = await resposta.json();

        if (resposta.ok && resultado.success) {
            document.getElementById('areaFormulario').style.display = 'none';
            document.getElementById('formCodigo').style.display = 'none';
            document.getElementById('mensagemSucesso').textContent =
                `O administrador principal de ${resultado.nomeEstabelecimento} vai analisar seu pedido. Você recebe acesso assim que for aceito.`;
            document.getElementById('codigoSucesso').style.display = 'block';
        } else {
            codigoInput.classList.add('input-erro');
            mostrarMensagem(resultado.message || 'Não foi possível entrar com esse código.');
            botao.innerText = textoOriginal;
            botao.disabled = false;
        }

    } catch (error) {
        console.error('Erro:', error);
        mostrarMensagem('Servidor offline. Verifique se a sua API Java está rodando.');
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}
