// Endereço único da API, usado por todas as páginas do site.
// Precisa ser carregado antes dos demais scripts de cada página.

// Trocar pelo endereço do serviço da API depois de criá-lo no Render.
const API_PRODUCAO = "https://suggesto-api.onrender.com";

// Aberto da própria máquina (localhost, 127.0.0.1 ou arquivo solto) usa o backend
// local; publicado em qualquer outro endereço, usa a API hospedada.
const rodandoLocal = ["localhost", "127.0.0.1", ""].includes(location.hostname);

window.API_ORIGIN = rodandoLocal ? "http://localhost:8080" : API_PRODUCAO;
window.API_BASE = window.API_ORIGIN + "/api";

// Client ID do "Entrar com Google" (público). Precisa ser o mesmo configurado na API.
window.GOOGLE_CLIENT_ID = "342563067513-3890o57ajbheevan610o669dldra5g86.apps.googleusercontent.com";
