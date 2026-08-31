// Aviso pra quem for mexer aqui: essa ponte de comunicação (IPC) e essa
// conexão direta com o banco não estão realmente em uso — o app conversa
// com o sistema só pela mesma API (REST) que o site e o celular usam.
// Isso ficou como um esboço de uma abordagem que não seguimos adiante.
const { contextBridge, ipcRenderer } = require('electron');
