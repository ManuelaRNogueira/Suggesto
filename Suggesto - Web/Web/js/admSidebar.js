const ADM_NAV = [
  { id: "inicio", href: "inicioAdm.html", label: "Início", icon: "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M9 22V12h6v10" },
  { id: "sugestoes", href: "sugestoesAdm.html", label: "Sugestões", badge: true, icon: "M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" },
  { id: "estatisticas", href: "estatisticasAdm.html", label: "Estatísticas", icon: "M18 20V10M12 20V4M6 20v-6" },
  { id: "usuarios", href: "perfilAdm.html", label: "Usuários", icon: "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2 M9 7a4 4 0 1 0 0-8 4 4 0 0 0 0 8 M23 21v-2a4 4 0 0 0-3-3.87 M16 3.13a4 4 0 0 1 0 7.75" },
];

function admRenderSidebar(paginaAtiva) {
  const alvo = document.getElementById("adm-sidebar");
  if (!alvo) return;

  const nome = localStorage.getItem("nomeUsuario") || "Administrador";
  const iniciais = admIniciais(nome);

  const navHtml = ADM_NAV.map(item => {
    const ativo = item.id === paginaAtiva ? " active" : "";
    const badge = item.badge ? `<span class="nav-badge" id="navBadgeSugestoes">—</span>` : "";
    return `<a class="nav-item${ativo}" href="${item.href}">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="${item.icon}"/></svg>
      ${item.label}${badge}
    </a>`;
  }).join("");

  alvo.innerHTML = `
    <aside class="sidebar">
      <div class="sidebar-logo">
        <img src="imagens/logo.png" alt="Suggesto">
        <div class="logo-text">Suggesto<span>Painel Admin</span></div>
      </div>
      <nav class="sidebar-nav">
        <div class="nav-section-label">Menu</div>
        ${navHtml}
      </nav>
      <div class="sidebar-footer">
        <div class="user-card">
          <div class="avatar">${iniciais}</div>
          <div class="user-info">
            <div class="user-name">${nome}</div>
            <div class="user-role">Administrador</div>
          </div>
          <button type="button" class="user-sair" title="Sair" id="admBtnSair">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1-2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
          </button>
        </div>
      </div>
    </aside>`;

  document.getElementById("admBtnSair")?.addEventListener("click", () => {
    if (confirm("Encerrar sessão?")) {
      localStorage.clear();
      window.location.href = "login.html";
    }
  });
}

async function admAtualizarBadgeSugestoes() {
  const badge = document.getElementById("navBadgeSugestoes");
  if (!badge) return;
  try {
    const metricas = await admBuscarMetricas();
    const total = metricas.novasSemana ?? metricas.totalSugestoes ?? 0;
    badge.textContent = total;
  } catch {
    badge.textContent = "—";
  }
}

function admInitPagina(paginaAtiva) {
  if (!admVerificarSessao()) return;
  admRenderSidebar(paginaAtiva);
  admAtualizarBadgeSugestoes();
}
