# Electron IPC Security Patterns

## Correct Preload Script Pattern

```javascript
// preload.js
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getData: () => ipcRenderer.invoke('get-data'),
  updateData: (data) => {
    if (!validateDataSchema(data)) throw new Error('Invalid data schema');
    return ipcRenderer.invoke('update-data', data);
  },
  onDataChanged: (callback) => {
    ipcRenderer.on('data-changed', (_event, data) => callback(data));
  },
});

function validateDataSchema(data) {
  return data && typeof data === 'object';
}
```

## Anti-Patterns to Avoid

```javascript
// ❌ NEVER: expose ipcRenderer directly
contextBridge.exposeInMainWorld('ipc', ipcRenderer);

// ❌ NEVER: expose require() or process
contextBridge.exposeInMainWorld('require', require);

// ❌ NEVER: set nodeIntegration = true
new BrowserWindow({ webPreferences: { nodeIntegration: true } }); // DANGEROUS
```

## Main Process IPC Handlers

Validate all input; return only necessary fields.

```javascript
ipcMain.handle('get-data', async (event) => {
  const data = await loadDataFromSecureLocation();
  return { id: data.id, name: data.name }; // Never return internalToken, adminFlag etc.
});

ipcMain.handle('update-data', async (event, data) => {
  if (!data || typeof data.id !== 'string' || typeof data.name !== 'string') {
    throw new Error('Invalid data schema');
  }
  const sanitized = {
    id: String(data.id).slice(0, 36),
    name: String(data.name).slice(0, 256),
  };
  await saveDataToSecureLocation(sanitized);
  return { ok: true };
});
```

## Safe File Path Access

```javascript
const SAFE_PATHS = {
  userDocuments: path.join(app.getPath('userData'), 'documents'),
};

ipcMain.handle('read-user-file', async (event, filename) => {
  const fullPath = path.normalize(path.join(SAFE_PATHS.userDocuments, filename));
  if (!fullPath.startsWith(SAFE_PATHS.userDocuments)) {
    throw new Error('Path traversal detected');
  }
  return fs.readFileSync(fullPath, 'utf8');
});
```
