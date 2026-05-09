---

name: electron-apps
description: Build secure, production-ready Electron desktop applications with best practices for IPC, CSP, state management, testing, packaging, and auto-updates.
applyTo: agent-electron-developer, agent-desktop-engineer
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Electron Application Development

Professional Electron application patterns for building secure, scalable desktop software.

## Quick Start

1. Set `nodeIntegration: false`, `sandbox: true`, `enableRemoteModule: false` in every `BrowserWindow`.
2. Use a preload script + `contextBridge.exposeInMainWorld` for all renderer↔main communication.
3. Add a strict CSP `<meta>` tag in every HTML file.
4. Package with Electron Forge; sign and notarize for production distribution.
5. Use `electron-updater` for auto-updates; always sign update artifacts.

## Reference Files

| File | Contents |
|------|----------|
| [`references/process-architecture.md`](references/process-architecture.md) | Main/renderer process model, IPC patterns, Content Security Policy |
| [`references/packaging-updates.md`](references/packaging-updates.md) | State management, Electron Forge packaging, macOS signing, auto-updates, performance tips |
| [`references/testing-security.md`](references/testing-security.md) | Unit tests (Jest), integration tests (WebdriverIO), full security checklist |

## Key Patterns

- **IPC**: `contextBridge.exposeInMainWorld` + `ipcMain.handle` — never expose raw Node APIs to renderer
- **State (single window)**: React Query over `window.api.*`
- **State (multi-window)**: `ipcMain` broadcast from main process
- **Never store secrets** in renderer or source — use `process.env` in main only
