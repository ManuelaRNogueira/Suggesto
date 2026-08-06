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

// Continua logado após um reload enquanto a sessão estiver no localStorage
const sessaoAtiva = () =>
  Boolean(localStorage.getItem("idUsuario")) &&
  localStorage.getItem("tipoUsuario") === "Administrador";

function App() {
  const [isLogado, setIsLogado] = useState(sessaoAtiva);

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
        </Route>

        {/* Telas de detalhe, com layout próprio */}
        <Route path="/estabelecimento/:id" element={<DetalhesEstabelecimento />} />
        <Route
          path="/estabelecimento/:id/recompensas"
          element={<MinhasRecompensas />}
        />
        <Route path="/recompensas" element={<MinhasRecompensas />} />
      </Routes>
    </HashRouter>
  );
}

export default App;
