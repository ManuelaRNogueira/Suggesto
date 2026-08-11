// ======================================================
// CADASTRO DO ESTABELECIMENTO - SUGGESTO
// ======================================================

let dadosEstabelecimento = {};
let idUsuarioCriado = null;
let fotoEstabelecimentoSelecionada = null;
let modoResponsavel = "nova";


// ======================================================
// PLANO SELECIONADO
// ======================================================

const planoEscolhido = sessionStorage.getItem("planoEscolhido");

if (!planoEscolhido) {
    window.location.href = "planos.html";
} else {
    const planoBadge = document.getElementById("planoBadge");
    const planoBadgeNome = document.getElementById("planoBadgeNome");

    if (planoBadge && planoBadgeNome) {
        planoBadgeNome.textContent = planoEscolhido;
        planoBadge.style.display = "inline-flex";
    }
}


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
    const cep = document.getElementById("cep").value.trim();
    const estado = document.getElementById("estado").value.trim().toUpperCase();
    const rua = document.getElementById("rua").value.trim();
    const numero = document.getElementById("numero").value.trim();
    const bairro = document.getElementById("bairro").value.trim();
    const cidade = document.getElementById("cidade").value.trim();
    const complemento = document.getElementById("complemento").value.trim();
    const horarioAbertura = document.getElementById("horarioAbertura").value;
    const horarioFechamento = document.getElementById("horarioFechamento").value;


    // Validação
    if (!nome) {
        mostrarMensagem("Digite o nome do estabelecimento.");
        return;
    }

    if (!cnpj) {
        mostrarMensagem("Digite o CNPJ do estabelecimento.");
        return;
    }

    if (cnpj.replace(/\D/g, "").length !== 14) {
        mostrarMensagem("Digite um CNPJ válido.");
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

    if (!cep) {
        mostrarMensagem("Digite o CEP do estabelecimento.");
        return;
    }

    if (!estado || estado.length !== 2) {
        mostrarMensagem("Digite o estado (UF) do estabelecimento.");
        return;
    }

    if (!rua) {
        mostrarMensagem("Digite a rua do estabelecimento.");
        return;
    }

    if (!numero) {
        mostrarMensagem("Digite o número do estabelecimento.");
        return;
    }

    if (!bairro) {
        mostrarMensagem("Digite o bairro do estabelecimento.");
        return;
    }

    if (!cidade) {
        mostrarMensagem("Digite a cidade do estabelecimento.");
        return;
    }


    // Guarda os dados para utilizar no cadastro final
    dadosEstabelecimento = {
        nome: nome,
        cnpj: cnpj,
        categoria: categoria,
        telefone: telefone,
        cep: cep,
        estado: estado,
        rua: rua,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        complemento: complemento,
        horarioFuncionamento: horarioAbertura && horarioFechamento
            ? `Seg. a Dom.: ${horarioAbertura} – ${horarioFechamento}`
            : ""
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
// ALTERNAR ENTRE "CRIAR CONTA" E "JÁ TENHO CONTA"
// ======================================================

function trocarModoResponsavel(modo) {
    modoResponsavel = modo;
    idUsuarioCriado = null; // troca de modo invalida qualquer tentativa anterior

    document.getElementById("modoNovaConta").classList.toggle("ativa", modo === "nova");
    document.getElementById("modoContaExistente").classList.toggle("ativa", modo === "existente");
    document.getElementById("camposContaNova").style.display = modo === "nova" ? "" : "none";
    document.getElementById("camposContaExistente").style.display = modo === "existente" ? "" : "none";

    document.getElementById("botaoCriarEstabelecimento").textContent =
        modo === "existente" ? "Vincular e criar estabelecimento" : "Criar estabelecimento";
}


// ======================================================
// CADASTRO FINAL
// ======================================================

async function cadastrar() {
    if (modoResponsavel === "existente") {
        await cadastrarComContaExistente();
    } else {
        await cadastrarComContaNova();
    }
}

async function cadastrarComContaExistente() {
    const email = document.getElementById("loginEmail").value.trim();
    const senha = document.getElementById("loginSenha").value;

    if (!email) {
        mostrarMensagem("Digite o e-mail da sua conta.");
        return;
    }

    if (!senha) {
        mostrarMensagem("Digite sua senha.");
        return;
    }

    const botao = document.getElementById("botaoCriarEstabelecimento");
    const textoOriginal = botao.innerText;
    botao.innerText = "Verificando...";
    botao.disabled = true;

    try {
        const respostaLogin = await fetch(`${window.API_BASE}/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email, senha })
        });

        const resultadoLogin = await respostaLogin.json();

        if (!respostaLogin.ok || !resultadoLogin.success) {
            mostrarMensagem(resultadoLogin.message || "Não foi possível entrar com essa conta.");
            botao.innerText = textoOriginal;
            botao.disabled = false;
            return;
        }

        idUsuarioCriado = resultadoLogin.idUsuario;
        await finalizarCadastroEstabelecimento(botao, textoOriginal, resultadoLogin.nome, email);
    } catch (error) {
        console.error("Erro:", error);
        mostrarMensagem("Servidor offline. Verifique se a sua API Java está rodando.");
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}

async function cadastrarComContaNova() {

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

    if (!/^[a-zA-Z0-9._]{3,30}$/.test(usuario)) {
        mostrarMensagem("Nome de usuário deve ter de 3 a 30 caracteres e usar apenas letras, números, pontos ou underscores.");
        return;
    }

    if (!cpf) {
        mostrarMensagem("Digite seu CPF.");
        return;
    }

    if (cpf.replace(/\D/g, "").length !== 11) {
        mostrarMensagem("Digite um CPF válido.");
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
    // ENVIA PARA O BACKEND
    // ==================================================

    const botao = document.getElementById("botaoCriarEstabelecimento");
    const textoOriginal = botao.innerText;

    botao.innerText = "Processando...";
    botao.disabled = true;

    try {
        // Passo 1 — cria o usuário responsável (só se ainda não foi criado,
        // para permitir tentar de novo sem duplicar a conta caso o passo 2 falhe).
        if (!idUsuarioCriado) {
            const respostaUsuario = await fetch(`${window.API_BASE}/cadastro`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    nome: nomeCompleto,
                    username: usuario,
                    email: email,
                    senha: senha,
                    tipoUsuario: "Administrador",
                    telefone: telefone,
                    cpf: cpf,
                    plano: planoEscolhido
                })
            });

            const resultadoUsuario = await respostaUsuario.json();

            if (!respostaUsuario.ok) {
                mostrarMensagem(resultadoUsuario.message || "Erro ao criar sua conta.");
                botao.innerText = textoOriginal;
                botao.disabled = false;
                return;
            }

            idUsuarioCriado = resultadoUsuario.idUsuario;
        }

        await finalizarCadastroEstabelecimento(botao, textoOriginal, nomeCompleto, email);
    } catch (error) {
        console.error("Erro:", error);
        mostrarMensagem("Servidor offline. Verifique se a sua API Java está rodando.");
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}

async function finalizarCadastroEstabelecimento(botao, textoOriginal, nomeResponsavel, emailResponsavel) {
    try {
        // Passo 2 — cria o estabelecimento vinculado ao usuário responsável.
        const formData = new FormData();
        formData.append("estabelecimento", new Blob([JSON.stringify({
            ...dadosEstabelecimento,
            idGerente: idUsuarioCriado
        })], { type: "application/json" }));

        if (fotoEstabelecimentoSelecionada) {
            formData.append("foto", fotoEstabelecimentoSelecionada);
        }

        const respostaEstab = await fetch(`${window.API_BASE}/estabelecimentos`, {
            method: "POST",
            body: formData
        });

        const textoResposta = await respostaEstab.text();
        let estabelecimentoSalvo;
        try {
            estabelecimentoSalvo = JSON.parse(textoResposta);
        } catch {
            estabelecimentoSalvo = textoResposta;
        }

        if (!respostaEstab.ok) {
            mostrarMensagem(
                typeof estabelecimentoSalvo === "string"
                    ? estabelecimentoSalvo
                    : "Erro ao cadastrar o estabelecimento."
            );
            botao.innerText = textoOriginal;
            botao.disabled = false;
            return;
        }

        sessionStorage.removeItem("planoEscolhido");

        // Já temos os dados do responsável recém-criado: loga automaticamente
        // para poder mandar direto pro painel do estabelecimento, sem passar
        // pela tela de login de novo.
        localStorage.setItem("idUsuario", idUsuarioCriado);
        localStorage.setItem("nomeUsuario", nomeResponsavel);
        localStorage.setItem("tipoUsuario", "Administrador");
        localStorage.setItem("emailUsuario", emailResponsavel);
        localStorage.setItem("idGerenteEfetivo", idUsuarioCriado);

        document.getElementById("codigoEstabelecimento").textContent = estabelecimentoSalvo.codigoAcesso;

        document.getElementById("etapaResponsavel").style.display = "none";
        document.getElementById("cadastroSucesso").style.display = "block";

        document.getElementById("indicador1").classList.remove("ativa");
        document.getElementById("indicador2").classList.add("ativa");

        document.getElementById("tituloCadastro").textContent = "Tudo certo!";
        document.getElementById("subtituloCadastro").textContent = "Seu estabelecimento foi cadastrado no Suggesto.";

        mostrarMensagem("Estabelecimento cadastrado com sucesso!", true);

    } catch (error) {
        console.error("Erro:", error);
        mostrarMensagem("Servidor offline. Verifique se a sua API Java está rodando.");
        botao.innerText = textoOriginal;
        botao.disabled = false;
    }
}


// ======================================================
// IR PARA O PAINEL DO ESTABELECIMENTO
// ======================================================

function irParaPainel() {
    window.location.href = "inicioAdm.html";
}


// ======================================================
// BUSCA DE ENDEREÇO PELO CEP (ViaCEP)
// ======================================================

const campoCep = document.getElementById("cep");

if (campoCep) {

    campoCep.addEventListener("input", async function () {

        let valor = this.value.replace(/\D/g, "");
        valor = valor.substring(0, 8);

        if (valor.length > 5) {
            valor = valor.replace(/^(\d{5})(\d)/, "$1-$2");
        }

        this.value = valor;

        const cepLimpo = valor.replace(/\D/g, "");

        if (cepLimpo.length === 8) {
            try {
                const resposta = await fetch(`https://viacep.com.br/ws/${cepLimpo}/json/`);
                const dados = await resposta.json();

                if (!dados.erro) {
                    document.getElementById("rua").value = dados.logradouro || "";
                    document.getElementById("bairro").value = dados.bairro || "";
                    document.getElementById("cidade").value = dados.localidade || "";
                    document.getElementById("estado").value = dados.uf || "";
                }
            } catch (error) {
                console.error("Erro ao buscar CEP:", error);
            }
        }
    });
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
// FOTO DO ESTABELECIMENTO
// ======================================================

const campoFotoEstabelecimento = document.getElementById("fotoEstabelecimento");

if (campoFotoEstabelecimento) {

    campoFotoEstabelecimento.addEventListener("change", function () {

        const arquivo = this.files[0];
        const preview = document.getElementById("previewFotoEstabelecimento");
        const nomeArquivo = document.getElementById("fotoEstabelecimentoNome");

        if (!arquivo) {
            fotoEstabelecimentoSelecionada = null;
            preview.style.display = "none";
            if (nomeArquivo) nomeArquivo.textContent = "Escolher arquivo (opcional)";
            return;
        }

        fotoEstabelecimentoSelecionada = arquivo;
        preview.src = URL.createObjectURL(arquivo);
        preview.style.display = "block";
        if (nomeArquivo) nomeArquivo.textContent = arquivo.name;
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