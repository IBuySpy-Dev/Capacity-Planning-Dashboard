# Electron CSP, Child Processes & Code Signing

## Content Security Policy

```html
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
  upgrade-insecure-requests;
">
```

| Directive | Purpose |
|---|---|
| `default-src 'none'` | Deny all by default |
| `script-src 'self'` | Block inline JS and external CDN scripts |
| `connect-src 'self'` | Restrict XHR/WebSocket to same origin |
| `object-src 'none'` | Disable plugins |
| `frame-ancestors 'none'` | Prevent clickjacking |

## Child Process Execution (Safe Pattern)

```javascript
const ALLOWED_COMMANDS = {
  git: 'git',
  python: process.platform === 'win32' ? 'python.exe' : 'python3',
};

ipcMain.handle('run-command', async (event, cmd, args) => {
  if (!ALLOWED_COMMANDS[cmd]) throw new Error(`Command '${cmd}' not allowed`);
  if (!Array.isArray(args) || args.some(arg => typeof arg !== 'string'))
    throw new Error('Invalid arguments');

  const unsafeChars = /[;&|<>$`(){}[\]\\]/;
  if (args.some(arg => unsafeChars.test(arg))) throw new Error('Invalid characters');

  return new Promise((resolve, reject) => {
    const proc = spawn(ALLOWED_COMMANDS[cmd], args, {
      shell: false, // CRITICAL: never use shell: true
      timeout: 30000,
      env: { PATH: process.env.PATH, HOME: process.env.HOME },
    });
    // ... handle stdout/stderr/close
  });
});
```

## Code Signing

**macOS:**
```bash
codesign --deep --force --verify --verbose --sign - /path/to/App.app
codesign -v /path/to/App.app
spctl -a -v /path/to/App.app
```

## Auto-Updates & Credential Storage

- Auto-updater: `autoUpdater.checkForUpdatesAndNotify()` — verify checksums via `crypto.createHash('sha256')` before install.
- Credentials: use `keytar.setPassword` / `keytar.getPassword` (OS keychain). **Never** store in config files or application memory.
- ASAR integrity: compute SHA-256 of `app.asar` on `app.on('ready')` and compare against `app.asar.sha256`; quit if mismatch.
