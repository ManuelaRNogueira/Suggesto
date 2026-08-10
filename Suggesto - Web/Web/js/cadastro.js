const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

const modoEquipe = new URLSearchParams(window.location.search).get('equipe') === '1';

if (modoEquipe) {
    document.getElementById('seletorPapel').style.display = 'none';
    document.getElementById('avisoEquipe').style.display = 'block';
    document.getElementById('tituloCadastro').textContent = 'Crie sua conta de administrador';
    document.getElementById('subtituloCadastro').textContent = 'Depois de criar sua conta, você vai entrar com o código do estabelecimento.';
}

function mostrarMensagem(mensagem, tipo = 'erro') {
    toastMsgErro.textContent = mensagem;

    if (tipo === 'sucesso') {
        toastErro.classList.add('sucesso');
    } else {
        toastErro.classList.remove('sucesso');
    }

    toastErro.classList.add('visivel');

    setTimeout(() => {
        toastErro.classList.remove('visivel');
    }, 3500);
}

function limparErros() {
    document.querySelectorAll('.form input').forEach(elemento => {
        elemento.classList.remove('input-erro');
    });
}

document.querySelectorAll('.form input').forEach(elemento => {
    elemento.addEventListener('input', () => elemento.classList.remove('input-erro'));
});

function isTelefoneValido(telefone) {
    let digitos = telefone.replace(/\D/g, '');
    if (digitos.length > 11 && digitos.startsWith('55')) {
        digitos = digitos.slice(2);
    }
    return /^[1-9][1-9](?:9\d{8}|[2-5]\d{7})$/.test(digitos);
}

function isUsernameValido(usuario) {
    return /^[a-zA-Z0-9._]{3,30}$/.test(usuario.trim());
}

function validarCampos() {
    limparErros();

    const usuario = document.getElementById('usuario');
    const email = document.getElementById('email');
    const telefone = document.getElementById('telefone');
    const cidade = document.getElementById('cidade');
    const senha = document.getElementById('senha');
    const confirmarSenha = document.getElementById('confirmarSenha');

    if (!usuario.value.trim() || !email.value.trim() || !telefone.value.trim() || !cidade.value.trim() || !senha.value.trim() || !confirmarSenha.value.trim()) {
        if (!usuario.value.trim()) usuario.classList.add('input-erro');
        if (!email.value.trim()) email.classList.add('input-erro');
        if (!telefone.value.trim()) telefone.classList.add('input-erro');
        if (!cidade.value.trim()) cidade.classList.add('input-erro');
        if (!senha.value.trim()) senha.classList.add('input-erro');
        if (!confirmarSenha.value.trim()) confirmarSenha.classList.add('input-erro');

        mostrarMensagem("Preencha todos os campos obrigatórios.");
        return false;
    }

    if (!isUsernameValido(usuario.value)) {
        usuario.classList.add('input-erro');
        mostrarMensagem("Nome de usuário deve ter de 3 a 30 caracteres e usar apenas letras, números, pontos ou underscores.");
        return false;
    }

    if (!email.value.includes("@") || !email.value.includes(".")) {
        email.classList.add('input-erro');
        mostrarMensagem("Digite um endereço de e-mail válido.");
        return false;
    }

    if (!isTelefoneValido(telefone.value)) {
        telefone.classList.add('input-erro');
        mostrarMensagem("Digite um telefone válido, com DDD (ex: (11) 91234-5678).");
        return false;
    }

    if (senha.value.length < 4) {
        senha.classList.add('input-erro');
        mostrarMensagem("A senha deve ter pelo menos 4 caracteres.");
        return false;
    }

    if (senha.value !== confirmarSenha.value) {
        senha.classList.add('input-erro');
        confirmarSenha.classList.add('input-erro');
        mostrarMensagem("As senhas não coincidem.");
        return false;
    }

    return true;
}

async function cadastrar() {
    if (!validarCampos()) return;

    const botao = document.querySelector('#formCliente .botao-principal');
    const textoOriginal = botao.innerText;

    botao.innerText = "Processando...";
    botao.disabled = true;

    const novoUsuario = {
        nome: document.getElementById('usuario').value.trim(),
        username: document.getElementById('usuario').value.trim(),
        email: document.getElementById('email').value.trim(),
        senha: document.getElementById('senha').value.trim(),
        tipoUsuario: modoEquipe ? "Administrador" : "Cliente",
        telefone: document.getElementById('telefone').value.trim(),
        cidade: document.getElementById('cidade').value.trim()
    };

    try {
        const resposta = await fetch("http://localhost:8080/api/cadastro", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(novoUsuario)
        });

        const resultado = await resposta.json();

        if (resposta.ok) {
            mostrarMensagem("Cadastro realizado com sucesso! Redirecionando...", "sucesso");

            setTimeout(() => {
                window.location.href = modoEquipe ? "login.html?equipe=1" : "login.html";
            }, 2000);
        } else {
            mostrarMensagem(resultado.message || "Erro ao cadastrar. Verifique os dados.");
            botao.innerText = textoOriginal;
            botao.disabled = false;
        }

    } catch (error) {
        console.error("Erro:", error);
        mostrarMensagem("Servidor offline. Verifique se a sua API Java está rodando.");
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}

const telefone = document.getElementById("telefone");

telefone.addEventListener("input", function() {
    let valor = telefone.value.replace(/\D/g, "");

    if (valor.length > 11) {
        valor = valor.substring(0, 11);
    }

    if (valor.length > 6) {
        telefone.value = "(" + valor.substring(0, 2) + ") "
        + valor.substring(2, 7) + "-"
        + valor.substring(7);
    }
    else if (valor.length > 2) {
        telefone.value = "(" + valor.substring(0, 2) + ") "
        + valor.substring(2);
    }
    else {
        telefone.value = valor;
    }
});
