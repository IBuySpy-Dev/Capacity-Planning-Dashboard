# Electron Process Architecture & IPC

## Process Model

Electron runs two processes:

- **Main Process**: Node.js runtime; controls app lifecycle, windows, and native APIs
- **Renderer Process**: Chromium; runs UI, DOM API, restricted system access (unless configured)

```javascript
// main.js — Main Process
const { app, BrowserWindow } = require('electron');

app.on('ready', () => {
  const win = new BrowserWindow({
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      sandbox: true,
      nodeIntegration: false,
      enableRemoteModule: false,
    },
  });
  win.loadFile('index.html');
});
```

## Inter-Process Communication (IPC)

Use preload scripts and `ipcMain`/`ipcRenderer` for secure communication.

```javascript
// preload.js — Runs in renderer context with main process access
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getData: () => ipcRenderer.invoke('get-data'),
  onUpdate: (callback) => ipcRenderer.on('update', (_event, data) => callback(data)),
});

// main.js — Handle IPC calls
ipcMain.handle('get-data', async () => {
  return { /* data */ };
});
ipcMain.on('set-data', (event, data) => {
  event.reply('ack', { ok: true });
});
```

## Content Security Policy (CSP)

Enforce strict CSP headers to prevent XSS and injection attacks.

```html
<!-- index.html -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'none';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
  font-src 'self';
  connect-src 'self';
  object-src 'none';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
">
```
