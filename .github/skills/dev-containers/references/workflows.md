# Dev Container Workflows

## GitHub Codespaces

`devcontainer.json` is automatically used by Codespaces. Configure machine type:

```json
{
  "codespaces": {
    "machineType": "standardLinux32gb"
  }
}
```

Options: `basicLinux32gb`, `standardLinux32gb`, `standardLinux64gb`.

## CI Integration

Run tests inside the dev container on CI to ensure environment parity:

```yaml
# GitHub Actions — run in dev container
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests in dev container
        uses: devcontainers/ci@v0.3
        with:
          runCmd: npm ci && npm test
```

## Lifecycle Hooks

| Hook | When | Use For |
|------|------|---------|
| `postCreateCommand` | Once on container create | Install dependencies |
| `postStartCommand` | Every container start | Start background services |
| `postAttachCommand` | Every VS Code attach | Print welcome message |

## Multi-Container Setup (Docker Compose)

```json
{
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "shutdownAction": "stopCompose"
}
```

```yaml
# docker-compose.yml
services:
  app:
    build: .devcontainer
    volumes:
      - ..:/workspace:cached
    command: sleep infinity
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: devpassword
```

## Best Practices

1. Commit `devcontainer.json` to git for team consistency.
2. Pin feature versions — avoid `latest`.
3. Keep container size minimal — only include necessary dependencies.
4. Document onboarding steps in the project README.
5. Test in Codespaces regularly to catch drift.
6. Use `postCreateCommand` scripts for idempotent setup (safe to re-run).

## References

- [VS Code Dev Containers](https://containers.dev/)
- [Dev Containers Specification](https://containers.dev/implementors/spec/)
- [GitHub Codespaces](https://docs.github.com/codespaces)
