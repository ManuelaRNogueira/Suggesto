// Endereço único da API, usado por todas as páginas do site.
// Em desenvolvimento cada pessoa roda o backend na própria máquina; ao hospedar,
// basta trocar estas duas linhas em vez de caçar a URL espalhada pelos arquivos.
// Precisa ser carregado antes dos demais scripts de cada página.
window.API_ORIGIN = "http://localhost:8080";
window.API_BASE = window.API_ORIGIN + "/api";
