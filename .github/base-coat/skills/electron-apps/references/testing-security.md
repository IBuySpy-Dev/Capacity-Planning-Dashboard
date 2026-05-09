# Electron Testing & Security

## Unit Tests (Jest)

```javascript
// src/utils/__tests__/math.test.js
import { add } from '../math';

describe('Math utils', () => {
  it('adds numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
  });
});
```

## Integration Tests (WebdriverIO)

Spectron is deprecated; use WebdriverIO with Electron driver.

```javascript
import { remote } from 'webdriverio';

describe('Electron App', () => {
  it('launches and shows window', async () => {
    const app = await remote({
      capabilities: {
        browserName: 'chrome',
        'wdio:electronService': {},
      },
    });
    const title = await app.getTitle();
    expect(title).toBe('My App');
    await app.deleteSession();
  });
});
```

## Security Checklist

- [ ] Node integration disabled (`nodeIntegration: false`)
- [ ] Remote module disabled (`enableRemoteModule: false`)
- [ ] Preload script sandboxed (`sandbox: true`)
- [ ] CSP meta tag enforced
- [ ] IPC: Validate all messages from renderer
- [ ] Code signing + notarization (production)
- [ ] No hardcoded secrets (use environment variables)
- [ ] Dependencies scanned with `npm audit`
- [ ] Auto-updates signed and verified
