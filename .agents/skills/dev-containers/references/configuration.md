# Dev Container Configuration

## devcontainer.json Structure

### Minimal Configuration

```json
{
  "name": "My Project",
  "image": "mcr.microsoft.com/vscode/devcontainers/python:3.12",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python", "ms-python.vscode-pylance"],
      "settings": { "python.defaultInterpreterPath": "/usr/local/bin/python" }
    }
  },
  "forwardPorts": [5000, 8000],
  "postCreateCommand": "pip install -r requirements.txt"
}
```

### Full Configuration

```json
{
  "name": "Full-Stack Development",
  "image": "mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04",
  "features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python", "dbaeumer.vscode-eslint", "esbenp.prettier-vscode"],
      "settings": { "editor.formatOnSave": true }
    }
  },
  "forwardPorts": [3000, 5000, 8000, 5432],
  "portsAttributes": {
    "3000": { "label": "Frontend", "onAutoForward": "notify" },
    "5432": { "label": "PostgreSQL", "onAutoForward": "silent" }
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "remoteUser": "vscode",
  "mounts": ["source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,readonly"]
}
```

## Docker Image Selection

| Image | Use Case |
|-------|---------|
| `mcr.microsoft.com/vscode/devcontainers/python:3.12` | Python projects |
| `mcr.microsoft.com/vscode/devcontainers/node:20` | Node.js projects |
| `mcr.microsoft.com/vscode/devcontainers/dotnet:8.0` | .NET projects |
| `mcr.microsoft.com/vscode/devcontainers/go:1.21` | Go projects |
| `mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04` | Multi-language |
| `mcr.microsoft.com/devcontainers/universal:2` | Full-stack (heavy) |

Use language-specific images for single-stack; `base:ubuntu` + features for multi-language.

## Common Features

```json
{
  "features": {
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/postgres:1": { "version": "15" }
  }
}
```

## Post-Create Command

```bash
#!/usr/bin/env bash
set -e
if [ -f "requirements.txt" ]; then pip install -r requirements.txt; fi
if [ -f "package.json" ]; then npm ci; fi
```

## Mounts for Credentials

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,readonly",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,readonly"
  ]
}
```

Never embed credentials in `Dockerfile` or `devcontainer.json`.
