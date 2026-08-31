// Aviso pra quem for mexer aqui: essa ponte de comunicação (IPC) e essa
// conexão direta com o banco não estão realmente em uso — o app conversa
// com o sistema só pela mesma API (REST) que o site e o celular usam.
// Isso ficou como um esboço de uma abordagem que não seguimos adiante.
const mysql = require('mysql2/promise')

const db = mysql.createPool ({
    host : "143.106.241.4",
    user : "cl204225",
    password : "cl*05102007",
    database : "cl204225",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = db; 