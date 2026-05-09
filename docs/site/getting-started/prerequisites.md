# Prerequisites

Before you can run the dashboard locally or deploy it to Azure, ensure the following are in place.

---

## Local development

| Prerequisite | Version | Notes |
|---|---|---|
| **Node.js** | 20 LTS | `node --version` to verify |
| **npm** | 10+ | Comes with Node 20 |
| **Docker Desktop** | Latest | For local SQL Server |
| **Git** | Any recent | — |
| **Azure CLI** | 2.57+ | `az --version` |

---

## Azure deployment

| Prerequisite | Notes |
|---|---|
| **Azure subscription** | Owner or Contributor access |
| **Microsoft Entra tenant** | For user authentication (can be the same tenant as the subscription) |
| **GitHub repository** | Fork or own copy of this repo |
| **GitHub Codespaces or local shell** | For running the bootstrap script |

### Azure permissions required to deploy

| Scope | Role | Why |
|---|---|---|
| Subscription | `Owner` or `User Access Administrator` | Bootstrap SPN needs to grant roles |
| Subscription | `Contributor` | Create resource group and cross-scope deployments |

!!! warning "Bootstrap must run before first deploy"
    The GitHub Actions workflow authenticates to Azure via OIDC. The bootstrap script creates the SPN and configures federated credentials. **You cannot deploy without running bootstrap first.**

---

## Required GitHub repository secrets

After bootstrap runs, these are pushed automatically to your repo:

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | Bootstrap SPN client ID |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

---

## GitHub Pages

To enable the documentation site:

1. Go to **Settings → Pages** in your GitHub repo.
2. Set **Source** to `GitHub Actions`.
3. The `docs.yml` workflow deploys automatically on pushes to `main` that touch `docs/` or `mkdocs.yml`.
