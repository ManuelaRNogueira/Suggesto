// Calcula se um estabelecimento está aberto agora, a partir do texto livre
// de horarioFuncionamento (ex: "Seg. a Dom.: 11:00 – 22:30").
// Usa o primeiro horário citado como abertura e o último como fechamento,
// e trata corretamente horários que atravessam a meia-noite (ex: 18:00 – 02:00).
function calcularStatusEstabelecimento(horarioTexto) {
  const horarios = String(horarioTexto || '').match(/(\d{1,2}):(\d{2})/g);

  if (!horarios || horarios.length < 2) {
    return { disponivel: false, aberto: false, label: 'Horário indisponível', detalhe: '' };
  }

  const paraMinutos = (str) => {
    const [h, m] = str.split(':').map(Number);
    return h * 60 + m;
  };

  const abreStr = horarios[0];
  const fechaStr = horarios[horarios.length - 1];
  const abreMin = paraMinutos(abreStr);
  const fechaMin = paraMinutos(fechaStr);

  const agora = new Date();
  const agoraMin = agora.getHours() * 60 + agora.getMinutes();

  const aberto = fechaMin > abreMin
    ? (agoraMin >= abreMin && agoraMin < fechaMin)
    : (agoraMin >= abreMin || agoraMin < fechaMin);

  return {
    disponivel: true,
    aberto,
    label: aberto ? 'Aberto' : 'Fechado',
    detalhe: aberto ? `Fecha às ${fechaStr}` : `Abre às ${abreStr}`,
  };
}
