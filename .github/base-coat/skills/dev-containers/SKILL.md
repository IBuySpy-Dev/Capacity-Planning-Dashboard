---
name: dev-containers
description: VS Code Dev Containers for reproducible development environments. Covers devcontainer.json configuration, Docker image selection, feature references, VS Code extensions in containers, GitHub Codespaces setup, and environment reproducibility.
compatibility: ["devops-engineer", "backend-dev", "frontend-dev"]
metadata:
  category: "Development & Operations"
  tags: ["dev-containers", "docker", "codespaces", "devcontainer", "reproducible-environments"]
  maturity: "production"
  audience: ["developers", "devops-engineers", "team-leads"]
allowed-tools: ["docker", "bash", "json", "yaml"]
---

# VS Code Dev Containers

Reproducible development environments using VS Code Dev Containers and GitHub Codespaces.
Eliminates "works on my machine" by bundling runtimes, tools, and extensions in Docker.

## Reference Files

| File | Contents |
|------|----------|
| [`references/configuration.md`](references/configuration.md) | devcontainer.json structure (minimal & full), image selection, features, extensions, port forwarding, mounts |
| [`references/workflows.md`](references/workflows.md) | GitHub Codespaces, CI integration, Docker Compose, lifecycle hooks, best practices |

## Benefits

- **Reproducible** — identical setup on laptop, CI, and Codespaces
- **Zero local toolchain** — all dependencies in the container
- **Fast onboarding** — clone repo and open in container
- **CI parity** — dev environment matches build/test environment

## Minimal Config

```json
{
  "name": "My Project",
  "image": "mcr.microsoft.com/vscode/devcontainers/python:3.12",
  "features": { "ghcr.io/devcontainers/features/github-cli:1": {} },
  "postCreateCommand": "pip install -r requirements.txt"
}
```

## Key Rules

- Commit `devcontainer.json` to git (team consistency)
- Pin feature and image versions — avoid `latest`
- Never embed credentials in `Dockerfile` or `devcontainer.json`
- Use `postCreateCommand` scripts for idempotent setup

## References

- [Dev Containers Specification](https://containers.dev/)
- [GitHub Codespaces](https://docs.github.com/codespaces)
