// Geolocalização do cliente + cálculo de distância — usado só em
// inicioCli.js pra separar "Perto de você" (raio real) de "Descubra Novos
// Locais". Não rastreia localização continuamente: pega a posição uma vez
// por carregamento de página (com cache curto do próprio navegador).

// Raio considerado "perto de você", em km. Único lugar pra mudar esse valor.
const RAIO_PERTO_KM = 5;

// Distância em linha reta entre duas coordenadas (fórmula de Haversine).
function calcularDistanciaKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Promise que nunca rejeita — permissão negada, posição indisponível, timeout
// ou navegador sem suporte tudo resolve como null, pra quem chama só
// precisar tratar "tenho localização" vs "não tenho", sem try/catch de erro.
function obterLocalizacaoUsuario() {
  return new Promise((resolve) => {
    if (!navigator.geolocation) {
      resolve(null);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (posicao) => resolve({ lat: posicao.coords.latitude, lng: posicao.coords.longitude }),
      () => resolve(null),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 },
    );
  });
}
