const { app, BrowserWindow, nativeTheme } = require('electron');
const path = require('path');

let win;

const createLoginWindow = () => {
    nativeTheme.themeSource = 'dark';

    win = new BrowserWindow({
        width: 800,
        height: 600,
        autoHideMenuBar: true,
        icon: path.join(__dirname, '../renderer/public/img/logoBalao.png'),
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            contextIsolation: true,
            nodeIntegration: true,
            webSecurity: false,
        },
    });

    win.maximize();
    win.loadURL('http://localhost:5173');
};

app.whenReady().then(() => {
    createLoginWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createLoginWindow();
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});
