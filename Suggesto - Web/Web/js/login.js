const emailInput = document.getElementById('email');
const senhaInput = document.getElementById('senha');
const toastErro = document.getElementById('toastErro');
const toastMsgErro = document.getElementById('toastMsgErro');

function mostrarErro(mensagem) {
    toastMsgErro.textContent = mensagem;
    toastErro.classList.add('visivel');
    
    setTimeout(() => {
        toastErro.classList.remove('visivel');
    }, 3500);
}

senhaInput.addEventListener('input', () => senhaInput.classList.remove('input-erro'));

if (new URLSearchParams(window.location.search).get('equipe') === '1') {
    const linkCadastro = document.getElementById('linkCadastro');
    if (linkCadastro) linkCadastro.href = 'cadastro.html?equipe=1';
}

function validarCampos() {
    const email = emailInput.value.trim();
    const senha = senhaInput.value.trim();

    if (!email || !senha) {
        if (!email) emailInput.classList.add('input-erro');
        if (!senha) senhaInput.classList.add('input-erro');
        mostrarErro("Por favor, preencha todos os campos.");
        return false;
    }

    if (!email.includes("@") || !email.includes(".")) {
        emailInput.classList.add('input-erro');
        mostrarErro("Digite um endereço de e-mail válido.");
        return false;
    }
    
    return true;
}

async function entrarSuggesto() {
    if (!validarCampos()) return;

    const botao = document.querySelector('.form button');
    const textoOriginal = botao.innerText;
    
    // Efeito de carregamento para o usuário saber que está processando
    botao.innerText = "Entrando...";
    botao.disabled = true;

    const dadosLogin = {
        email: emailInput.value.trim(),
        senha: senhaInput.value.trim()
    };

    try {
        const resposta = await fetch(`${window.API_BASE}/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(dadosLogin)
        });

        const resultado = await resposta.json();

        // O backend Java retorna status 200 (ok) e "success": true quando dá certo
        if (resposta.ok && resultado.success) {

            const modoEquipe = new URLSearchParams(window.location.search).get('equipe') === '1';

            if (modoEquipe && resultado.tipoUsuario !== "Administrador") {
                mostrarErro("Você precisa de uma conta de administrador para entrar em uma equipe.");
                botao.innerText = textoOriginal;
                botao.disabled = false;
                return;
            }

            // 1. Guardamos os dados no navegador para usar nas próximas telas
            localStorage.setItem("idUsuario", resultado.idUsuario);
            localStorage.setItem("nomeUsuario", resultado.nome);
            localStorage.setItem("tipoUsuario", resultado.tipoUsuario);
            localStorage.setItem("emailUsuario", dadosLogin.email);

            // 2. REDIRECIONAMENTO DINÂMICO
            if (modoEquipe) {
                window.location.href = "entrarCodigo.html";
            } else if (resultado.tipoUsuario === "Administrador") {
                // O Java manda exatamente a string do Enum (ex: "Administrador" ou "Cliente")
                window.location.href = "inicioAdm.html";
            } else {
                window.location.href = "inicioCli.html";
            }

        } else {
            // Conta não encontrada, senha errada ou campo vazio (Status 400 ou 401)
            // A mensagem que aparece no toast vem direto do Java (resultado.message)
            emailInput.classList.add('input-erro');
            senhaInput.classList.add('input-erro');
            mostrarErro(resultado.message || "Falha na autenticação.");
            
            // Restaura o botão
            botao.innerText = textoOriginal;
            botao.disabled = false;
        }
    } catch (error) {
        // Cai aqui se o Spring Boot (Java) estiver desligado
        console.error("Erro na requisição:", error);
        mostrarErro("Servidor offline. Verifique se a API está rodando.");
        
        // Restaura o botão
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}