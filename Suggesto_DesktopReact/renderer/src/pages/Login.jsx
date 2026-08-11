import React, { useEffect, useState } from "react";
import { API_BASE } from "../api/admin";
import "./Login.css"
//recebemos a prop aoLogar do app.jsx
export default function Login({ aoLogar }) {
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [mensagem, setMensagem] = useState(
    "Descubra o que seus clientes andam comentando",
  );
  const [msgColor, setMsgColor] = useState("#d8c7ff");
  const [fraseIndex, setFraseIndex] = useState(0);
  const [opacity, setOpacity] = useState(1);
  const [isLogado, setIsLogado] = useState(false);

  const frases = [
    "Monitore, aprenda e evolua com o que dizem por aí.",
    "Fique de olho no que seus clientes pensam de você.",
    "Veja como seu público está reagindo em tempo real.",
    "Fique por dentro e evolua com as sugestões.",
    "Quem escuta o cliente, cresce com ele.",
    "A opinião do cliente é o mapa do sucesso.",
    "Toda crítica é um convite pra melhorar.",
    "A mudança começa quando alguém decide ouvir.",
  ];

  useEffect(() => {
    const intervalo = setInterval(() => {
      setOpacity(0);
      setTimeout(() => {
        setFraseIndex((prev) => (prev + 1) % frases.length);
        setMensagem(frases[(fraseIndex + 1) % frases.length]);
        setOpacity(1);
      }, 1000);
    }, 4000);
    return () => clearInterval(intervalo);
  }, [fraseIndex]);

  const handleLogin = async () => {
    try {
      const resposta = await fetch(`${API_BASE}/login/admin`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), senha: senha }),
      });

      const resultado = await resposta.json();

      if (resposta.ok && resultado.success) {

        localStorage.setItem("nomeUsuario", resultado.nome)
        localStorage.setItem("emailUsuario", email)
        localStorage.setItem("idUsuario", resultado.idUsuario)
        localStorage.setItem("tipoUsuario", resultado.tipoUsuario)
        localStorage.setItem("idGerenteEfetivo", resultado.idGerenteEfetivo ?? resultado.idUsuario)

        setMensagem("Conectando...");
        setMsgColor("#c8e6c9");

        setTimeout(() => {
          aoLogar();
        }, 500);
      } else {
        setMensagem(resultado.message || "Erro ao fazer login");
        setMsgColor("#ffcdd2");
      }
    } catch (error) {
      setMensagem("Erro de comunicação com o servidor");
      setMsgColor("#ffcdd2");
    }
  };

  return (
    <div className="main-container">
      <div id="esquerda">
        <div id="tituloContainer">
          <div id="titulologo">
            <div id="titulo">Suggesto</div>
            <img src="/img/logoBalao.png" id="Logo" alt="Logo" />
          </div>
          <div id="fraseAdm">Administradores</div>
        </div>

        <div id="login">
          <h1>Faça seu login</h1>
          <p id="fraseLogin" style={{ opacity: opacity, color: msgColor }}>
            {mensagem}
          </p>
          <div id="divLogin">
            <input
              type="email"
              placeholder="Digite seu email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoFocus
            />
            <input
              type="password"
              placeholder="Digite sua senha"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
            />
            <button id="entrar" onClick={handleLogin}>
              Entrar
            </button>
          </div>
        </div>
      </div>

      <div id="direita">
        <div id="conteudo-direita">
          <img src="/img/Feedback-bro.svg" id="imagenzinha" alt="Ilustração" />
          <h1 id="Frase">Toda mudança começa com uma sugestão</h1>
        </div>
      </div>
      <p id="creditos">© 2026 Suggesto — Painel Administrativo</p>
    </div>
  );
}
