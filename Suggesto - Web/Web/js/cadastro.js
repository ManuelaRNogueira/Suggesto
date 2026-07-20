const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

function isPaginaAdmin() {
    return window.location.pathname.includes('cadastroAdm');
}

document.addEventListener("DOMContentLoaded", function () {
    const camposAdmin = document.getElementById("campos-admin");

    if (isPaginaAdmin()) {
        if (camposAdmin) camposAdmin.style.display = "block";

        const planoEscolhido = sessionStorage.getItem("planoEscolhido");
        const elPlano = document.getElementById("planoSelecionado");

        if (elPlano && planoEscolhido) {
            elPlano.style.display = "block";
            elPlano.textContent = `Plano selecionado: ${planoEscolhido}`;
        }
    } else if (camposAdmin) {
        function atualizarCampos() {
            const selecionado = document.querySelector('input[name="role"]:checked');
            if (!selecionado) return;

            camposAdmin.style.display = selecionado.value === "admin" ? "block" : "none";
            limparErros();
        }

        document.body.addEventListener("change", function (e) {
            if (e.target.name === "role") atualizarCampos();
        });

        atualizarCampos();
    }
});

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
    document.querySelectorAll('.form input, .form select').forEach(elemento => {
        elemento.classList.remove('input-erro');
    });
}

document.querySelectorAll('.form input, .form select').forEach(elemento => {
    elemento.addEventListener('input', () => elemento.classList.remove('input-erro'));
    elemento.addEventListener('change', () => elemento.classList.remove('input-erro'));
});

function isTelefoneValido(telefone) {
    let digitos = telefone.replace(/\D/g, '');
    if (digitos.length > 11 && digitos.startsWith('55')) {
        digitos = digitos.slice(2);
    }
    return /^[1-9][1-9](?:9\d{8}|[2-5]\d{7})$/.test(digitos);
}

function obterRole() {
    if (isPaginaAdmin()) return "admin";

    const roleElement = document.querySelector('input[name="role"]:checked');
    return roleElement ? roleElement.value : "cliente";
}

function validarCampos() {
    limparErros();

    const usuario = document.getElementById('usuario');
    const email = document.getElementById('email');
    const senha = document.getElementById('senha');
    const confirmarSenha = document.getElementById('confirmarSenha');
    const role = obterRole();

    if (!usuario.value.trim() || !email.value.trim() || !senha.value.trim() || !confirmarSenha.value.trim()) {
        if (!usuario.value.trim()) usuario.classList.add('input-erro');
        if (!email.value.trim()) email.classList.add('input-erro');
        if (!senha.value.trim()) senha.classList.add('input-erro');
        if (!confirmarSenha.value.trim()) confirmarSenha.classList.add('input-erro');

        mostrarMensagem("Preencha todos os campos obrigatórios.");
        return false;
    }

    if (!email.value.includes("@") || !email.value.includes(".")) {
        email.classList.add('input-erro');
        mostrarMensagem("Digite um endereço de e-mail válido.");
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

    const telefone = document.getElementById('telefone');
    const cidade = document.getElementById('cidade');

    if (role === 'cliente') {
        if (telefone && !telefone.value.trim()) {
            telefone.classList.add('input-erro');
            mostrarMensagem("Informe seu telefone.");
            return false;
        }
        if (telefone && telefone.value.trim() && !isTelefoneValido(telefone.value)) {
            telefone.classList.add('input-erro');
            mostrarMensagem("Digite um telefone válido, com DDD (ex: (11) 91234-5678).");
            return false;
        }
        if (cidade && !cidade.value.trim()) {
            cidade.classList.add('input-erro');
            mostrarMensagem("Informe sua cidade.");
            return false;
        }
    }

    if (role === 'admin') {
        const nomeCompleto = document.getElementById('nomeCompleto');
        const cpf = document.getElementById('cpf');
        const cargo = document.getElementById('cargo');

        if (!nomeCompleto?.value.trim() || !cpf?.value.trim() || !telefone?.value.trim() || !cargo?.value || !cidade?.value.trim()) {
            if (!nomeCompleto?.value.trim()) nomeCompleto?.classList.add('input-erro');
            if (!cpf?.value.trim()) cpf?.classList.add('input-erro');
            if (!telefone?.value.trim()) telefone?.classList.add('input-erro');
            if (!cargo?.value) cargo?.classList.add('input-erro');
            if (!cidade?.value.trim()) cidade?.classList.add('input-erro');

            mostrarMensagem("Preencha todos os campos de administrador.");
            return false;
        }

        if (cpf.value.trim().length < 11) {
            cpf.classList.add('input-erro');
            mostrarMensagem("Digite um CPF válido.");
            return false;
        }

        if (!isTelefoneValido(telefone.value)) {
            telefone.classList.add('input-erro');
            mostrarMensagem("Digite um telefone válido, com DDD (ex: (11) 91234-5678).");
            return false;
        }
    }

    return true;
}

async function cadastrar() {
    const role = obterRole();

    if (role === 'admin') {
        const planoEscolhido = sessionStorage.getItem("planoEscolhido");
        if (!planoEscolhido || !planoEscolhido.trim()) {
            mostrarMensagem("Você precisa escolher um plano antes de cadastrar!");
            window.location.href = 'planos.html';
            return;
        }
    }

    if (!validarCampos()) return;

    const botao = document.querySelector('.form button');
    const textoOriginal = botao.innerText;

    botao.innerText = "Processando...";
    botao.disabled = true;

    const telefoneEl = document.getElementById('telefone');
    const cidadeEl = document.getElementById('cidade');

    const novoUsuario = {
        nome: document.getElementById('usuario').value.trim(),
        email: document.getElementById('email').value.trim(),
        senha: document.getElementById('senha').value.trim(),
        tipoUsuario: role === "admin" ? "Administrador" : "Cliente",
        telefone: telefoneEl ? telefoneEl.value.trim() : "",
        cidade: cidadeEl ? cidadeEl.value.trim() : ""
    };

    if (role === "admin") {
        const nomeCompleto = document.getElementById('nomeCompleto');
        novoUsuario.nome = nomeCompleto ? nomeCompleto.value.trim() : novoUsuario.nome;
        novoUsuario.cpf = document.getElementById('cpf').value.trim();
        novoUsuario.cargo = document.getElementById('cargo').value;
        novoUsuario.plano = sessionStorage.getItem("planoEscolhido");
    }

    try {
        const resposta = await fetch("http://localhost:8080/api/cadastro", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(novoUsuario)
        });

        const resultado = await resposta.json();

        if (resposta.ok) {
            if (role === "admin") {
                sessionStorage.removeItem("planoEscolhido");
            }

            mostrarMensagem("Cadastro realizado com sucesso! Redirecionando...", "sucesso");

            setTimeout(() => {
                window.location.href = "login.html";
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
