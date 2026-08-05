// ======================================================
// CADASTRO DO ESTABELECIMENTO - SUGGESTO
// ======================================================

let dadosEstabelecimento = {};


// ======================================================
// TOAST
// ======================================================

function mostrarMensagem(mensagem, sucesso = false) {
    const toast = document.getElementById("toastErro");
    const mensagemToast = document.getElementById("toastMsgErro");

    mensagemToast.textContent = mensagem;

    if (sucesso) {
        toast.classList.add("sucesso");
    } else {
        toast.classList.remove("sucesso");
    }

    toast.classList.add("visivel");

    setTimeout(() => {
        toast.classList.remove("visivel");
    }, 3000);
}


// ======================================================
// ETAPA 1 → ETAPA 2
// ======================================================

function irParaEtapa2() {

    const nome = document.getElementById("nomeEstabelecimento").value.trim();
    const cnpj = document.getElementById("cnpj").value.trim();
    const categoria = document.getElementById("categoria").value;
    const telefone = document.getElementById("telefoneEstabelecimento").value.trim();
    const cidade = document.getElementById("cidade").value.trim();
    const endereco = document.getElementById("endereco").value.trim();


    // Validação
    if (!nome) {
        mostrarMensagem("Digite o nome do estabelecimento.");
        return;
    }

    if (!cnpj) {
        mostrarMensagem("Digite o CNPJ do estabelecimento.");
        return;
    }

    if (!categoria) {
        mostrarMensagem("Selecione o segmento do estabelecimento.");
        return;
    }

    if (!telefone) {
        mostrarMensagem("Digite o telefone do estabelecimento.");
        return;
    }

    if (!cidade) {
        mostrarMensagem("Digite a cidade do estabelecimento.");
        return;
    }

    if (!endereco) {
        mostrarMensagem("Digite o endereço do estabelecimento.");
        return;
    }


    // Guarda os dados para utilizar no cadastro final
    dadosEstabelecimento = {
        nome: nome,
        cnpj: cnpj,
        categoria: categoria,
        telefone: telefone,
        cidade: cidade,
        endereco: endereco
    };


    // Esconde etapa 1
    document.getElementById("etapaEstabelecimento").style.display = "none";

    // Mostra etapa 2
    document.getElementById("etapaResponsavel").style.display = "block";


    // Atualiza indicador
    document.getElementById("indicador1").classList.remove("ativa");
    document.getElementById("indicador2").classList.add("ativa");


    // Atualiza textos
    document.getElementById("tituloCadastro").textContent =
        "Cadastre o responsável";

    document.getElementById("subtituloCadastro").textContent =
        "Agora crie o acesso do responsável pelo estabelecimento.";
}


// ======================================================
// ETAPA 2 → ETAPA 1
// ======================================================

function voltarParaEtapa1() {

    // Esconde etapa 2
    document.getElementById("etapaResponsavel").style.display = "none";

    // Mostra etapa 1
    document.getElementById("etapaEstabelecimento").style.display = "block";


    // Atualiza indicador
    document.getElementById("indicador2").classList.remove("ativa");
    document.getElementById("indicador1").classList.add("ativa");


    // Volta os textos
    document.getElementById("tituloCadastro").textContent =
        "Cadastre seu estabelecimento";

    document.getElementById("subtituloCadastro").textContent =
        "Comece criando o perfil do seu estabelecimento no Suggesto.";
}


// ======================================================
// CADASTRO FINAL
// ======================================================

function cadastrar() {

    const nomeCompleto =
        document.getElementById("nomeCompleto").value.trim();

    const usuario =
        document.getElementById("usuario").value.trim();

    const cpf =
        document.getElementById("cpf").value.trim();

    const email =
        document.getElementById("email").value.trim();

    const telefone =
        document.getElementById("telefone").value.trim();

    const senha =
        document.getElementById("senha").value;

    const confirmarSenha =
        document.getElementById("confirmarSenha").value;


    // ==================================================
    // VALIDAÇÕES
    // ==================================================

    if (!nomeCompleto) {
        mostrarMensagem("Digite seu nome completo.");
        return;
    }

    if (!usuario) {
        mostrarMensagem("Digite um nome de usuário.");
        return;
    }

    if (!cpf) {
        mostrarMensagem("Digite seu CPF.");
        return;
    }

    if (!email) {
        mostrarMensagem("Digite seu e-mail.");
        return;
    }

    if (!telefone) {
        mostrarMensagem("Digite seu telefone.");
        return;
    }

    if (!senha) {
        mostrarMensagem("Digite uma senha.");
        return;
    }

    if (senha.length < 6) {
        mostrarMensagem("A senha deve ter pelo menos 6 caracteres.");
        return;
    }

    if (!confirmarSenha) {
        mostrarMensagem("Confirme sua senha.");
        return;
    }

    if (senha !== confirmarSenha) {
        mostrarMensagem("As senhas não coincidem.");
        return;
    }


    // ==================================================
    // DADOS COMPLETOS
    // ==================================================

    const cadastro = {

        estabelecimento: dadosEstabelecimento,

        responsavel: {
            nomeCompleto: nomeCompleto,
            usuario: usuario,
            cpf: cpf,
            email: email,
            telefone: telefone,
            senha: senha
        }

    };


    console.log("CADASTRO COMPLETO:");
    console.log(cadastro);


    // ==================================================
    // GERA CÓDIGO DO ESTABELECIMENTO
    // ==================================================

    const codigo =
        "SGT-" +
        Math.floor(100000 + Math.random() * 900000);


    document.getElementById("codigoEstabelecimento").textContent = codigo;


    // ==================================================
    // ESCONDE ETAPA 2
    // ==================================================

    document.getElementById("etapaResponsavel").style.display = "none";


    // ==================================================
    // MOSTRA TELA DE SUCESSO
    // ==================================================

    document.getElementById("cadastroSucesso").style.display = "block";


    // Atualiza indicador
    document.getElementById("indicador1").classList.remove("ativa");
    document.getElementById("indicador2").classList.add("ativa");


    // Atualiza título
    document.getElementById("tituloCadastro").textContent =
        "Tudo certo!";

    document.getElementById("subtituloCadastro").textContent =
        "Seu estabelecimento foi cadastrado no Suggesto.";


    mostrarMensagem(
        "Estabelecimento cadastrado com sucesso!",
        true
    );
}


// ======================================================
// IR PARA LOGIN
// ======================================================

function irParaLogin() {

    // Se você tiver uma página login.html:
    window.location.href = "login.html";

    // Se estiver usando outro sistema de rotas,
    // troque a linha acima pela rota correspondente.
}


// ======================================================
// MÁSCARA DE CNPJ
// ======================================================

const campoCnpj = document.getElementById("cnpj");

if (campoCnpj) {

    campoCnpj.addEventListener("input", function () {

        let valor = this.value.replace(/\D/g, "");

        valor = valor.substring(0, 14);

        valor = valor.replace(/^(\d{2})(\d)/, "$1.$2");
        valor = valor.replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3");
        valor = valor.replace(
            /^(\d{2})\.(\d{3})\.(\d{3})(\d)/,
            "$1.$2.$3/$4"
        );
        valor = valor.replace(
            /^(\d{2})\.(\d{3})\.(\d{3})\/(\d{4})(\d)/,
            "$1.$2.$3/$4-$5"
        );

        this.value = valor;
    });
}


// ======================================================
// MÁSCARA DE CPF
// ======================================================

const campoCpf = document.getElementById("cpf");

if (campoCpf) {

    campoCpf.addEventListener("input", function () {

        let valor = this.value.replace(/\D/g, "");

        valor = valor.substring(0, 11);

        valor = valor.replace(/^(\d{3})(\d)/, "$1.$2");
        valor = valor.replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3");
        valor = valor.replace(
            /^(\d{3})\.(\d{3})\.(\d{3})(\d)/,
            "$1.$2.$3-$4"
        );

        this.value = valor;
    });
}


// ======================================================
// MÁSCARA DE TELEFONE DO ESTABELECIMENTO
// ======================================================

const campoTelefoneEstabelecimento =
    document.getElementById("telefoneEstabelecimento");

if (campoTelefoneEstabelecimento) {

    campoTelefoneEstabelecimento.addEventListener("input", function () {

        let valor = this.value.replace(/\D/g, "");

        valor = valor.substring(0, 11);

        if (valor.length <= 10) {

            valor = valor.replace(
                /^(\d{2})(\d)/,
                "($1) $2"
            );

            valor = valor.replace(
                /(\d{4})(\d)/,
                "$1-$2"
            );

        } else {

            valor = valor.replace(
                /^(\d{2})(\d)/,
                "($1) $2"
            );

            valor = valor.replace(
                /(\d{5})(\d)/,
                "$1-$2"
            );
        }

        this.value = valor;
    });
}


// ======================================================
// MÁSCARA DE TELEFONE DO RESPONSÁVEL
// ======================================================

const campoTelefone =
    document.getElementById("telefone");

if (campoTelefone) {

    campoTelefone.addEventListener("input", function () {

        let valor = this.value.replace(/\D/g, "");

        valor = valor.substring(0, 11);

        if (valor.length <= 10) {

            valor = valor.replace(
                /^(\d{2})(\d)/,
                "($1) $2"
            );

            valor = valor.replace(
                /(\d{4})(\d)/,
                "$1-$2"
            );

        } else {

            valor = valor.replace(
                /^(\d{2})(\d)/,
                "($1) $2"
            );

            valor = valor.replace(
                /(\d{5})(\d)/,
                "$1-$2"
            );
        }

        this.value = valor;
    });
}