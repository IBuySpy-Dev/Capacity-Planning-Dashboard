# Electron Packaging, State Management & Auto-Updates

## State Management

### Local State (Single Window)

Use React, Vue, or Svelte with local state.

```javascript
import { useQuery, useMutation } from '@tanstack/react-query';

export const useAppData = () => useQuery({
  queryKey: ['app-data'],
  queryFn: async () => window.api.getData(),
});

export const useUpdateData = () => useMutation({
  mutationFn: (data) => window.api.updateData(data),
});
```

### Shared State (Multi-Window)

```javascript
// main.js — Shared state via event emission
let appState = {};
ipcMain.handle('state:get', () => appState);
ipcMain.handle('state:set', (event, newState) => {
  appState = { ...appState, ...newState };
  mainWindow?.webContents?.send('state:changed', appState);
  return appState;
});
```

## Packaging with Electron Forge

```javascript
// forge.config.js
module.exports = {
  packagerConfig: {
    asar: true,
    icon: './assets/icon',
    osxSign: { identity: 'Developer ID Application: Company (ID)' },
  },
  makers: [
    { name: '@electron-forge/maker-squirrel', config: { certificateFile: './cert.pfx', certificatePassword: process.env.CERT_PASSWORD } },
    { name: '@electron-forge/maker-dmg' },
    { name: '@electron-forge/maker-zip' },
  ],
};
```

### macOS Signing & Notarization

```bash
npm run make -- --platform darwin
xcrun altool --notarize-app --file MyApp.dmg --primary-bundle-id com.example.app \
  -u developer@apple.com -p @keychain:Developer-ID
```

## Auto-Updates with electron-updater

```javascript
import { autoUpdater } from 'electron-updater';

autoUpdater.setFeedURL({ provider: 'github', owner: 'myorg', repo: 'myapp', token: process.env.GH_TOKEN });
autoUpdater.checkForUpdatesAndNotify();
autoUpdater.on('update-downloaded', () => autoUpdater.quitAndInstall());
```

## Performance Tips

- **Code splitting**: Lazy-load renderer code with `dynamic import()`
- **V8 code caching**: Pre-compile scripts for faster startup
- **Memory profiling**: Use Chrome DevTools in dev mode
- **Native modules**: Compile with `native-addon-build` to match Electron's Node.js version

## Common Patterns

- **Always-on-top**: `win.setAlwaysOnTop(true)`
- **Tray menu**: `Menu.setApplicationMenu(createMenu())`
- **Deep linking**: `deep-linking` protocol + `app.on('open-url')`
- **Crash reporting**: Integrate Sentry or similar
