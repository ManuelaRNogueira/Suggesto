import React, { useState } from "react";

import { HashRouter, Routes, Route } from "react-router-dom";

import Login from "./pages/Login";
import AdminShell from "./components/AdminShell";
import Inicio from "./pages/admin/Inicio";
import Sugestoes from "./pages/admin/Sugestoes";
import Estatisticas from "./pages/admin/Estatisticas";
import Perfil from "./pages/admin/Perfil";
import Solicitacoes from "./pages/admin/Solicitacoes";
import Dashboard from "./pages/Dashboard";
import DetalhesEstabelecimento from "./pages/DetalhesEstabelecimento";
import MinhasRecompensas from "./pages/MinhasRecompensas";

import "./App.css";

function App() {
  // Sempre exige login ao abrir o app; o Electron mantém o localStorage
  // entre execuções, então não dá pra confiar nele pra manter a sessão.
  const [isLogado, setIsLogado] = useState(false);

  if (!isLogado) {
    return <Login aoLogar={() => setIsLogado(true)} />;
  }

  return (
    <HashRouter>
      <Routes>
        {/* Painel administrativo: sidebar e cabeçalho compartilhados */}
        <Route element={<AdminShell />}>
          <Route path="/" element={<Inicio />} />
          <Route path="/sugestoes" element={<Sugestoes />} />
          <Route path="/estatisticas" element={<Estatisticas />} />
          <Route path="/estabelecimentos" element={<Dashboard />} />
          <Route path="/perfil" element={<Perfil />} />
          <Route path="/solicitacoes" element={<Solicitacoes />} />
          <Route path="/recompensas" element={<MinhasRecompensas />} />
          <Route
            path="/estabelecimento/:id/recompensas"
            element={<MinhasRecompensas />}
          />
        </Route>

        {/* Tela de detalhe, com layout próprio */}
        <Route path="/estabelecimento/:id" element={<DetalhesEstabelecimento />} />
      </Routes>
    </HashRouter>
  );
}

export default App;
