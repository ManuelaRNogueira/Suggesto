// Mesma regra de senha da API (ver SenhaUtil.java). Aqui é só pra avisar antes
// de enviar; quem decide de verdade é o servidor.
const SENHA_TAMANHO_MINIMO = 8;
const SENHA_TAMANHO_MAXIMO = 64;

// Devolve a mensagem de erro, ou null se a senha serve.
function validarSenhaForte(senha) {
    const valor = (senha || "").trim();

    if (!valor) return "Digite uma senha.";
    if (valor.length < SENHA_TAMANHO_MINIMO) {
        return `A senha deve ter pelo menos ${SENHA_TAMANHO_MINIMO} caracteres.`;
    }
    if (valor.length > SENHA_TAMANHO_MAXIMO) {
        return `A senha deve ter no máximo ${SENHA_TAMANHO_MAXIMO} caracteres.`;
    }
    if (!/\p{L}/u.test(valor) || !/\d/.test(valor) || !/[^\p{L}\d\s]/u.test(valor)) {
        return "A senha deve ter pelo menos uma letra, um número e um caractere especial (ex: ! @ # $ %).";
    }
    return null;
}
