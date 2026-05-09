# RBAC Topology

Two **system-assigned managed identities** are used — one for the App Service and one for the Function App. Both are granted least-privilege roles at appropriate scopes.

---

## Role assignment map

```mermaid
flowchart LR
    classDef mi fill:#dbeafe,stroke:#2563eb
    classDef role fill:#dcfce7,stroke:#16a34a,color:#14532d,font-size:11px
    classDef scope fill:#f3e8ff,stroke:#7c3aed,font-size:11px

    WebMI[App Service MI\napp-capdash-prod]:::mi
    WorkerMI[Function App MI\nfunc-capdash-worker]:::mi

    subgraph SubScope["Subscription scope"]
        UAA["User Access\nAdministrator"]:::role
        ContribSub["Contributor"]:::role
    end

    subgraph RGScope["Resource Group scope"]
        ContribRG["Contributor"]:::role
        SQLContrib["SQL DB Contributor"]:::role
        KVSecrets["Key Vault\nSecrets User"]:::role
        APPICollab["Monitoring Metrics\nPublisher"]:::role
        Reader["Reader"]:::role
    end

    WebMI --> KVSecrets
    WebMI --> SQLContrib
    WebMI --> APPICollab
    WebMI --> Reader

    WorkerMI --> KVSecrets
    WorkerMI --> APPICollab
    WorkerMI --> Reader

    subgraph SPNScope["Bootstrap SPN — CI/CD only"]
        direction TB
        BSPN[bootstrap-capdash SPN\nGitHub Actions OIDC]:::mi
        BSPN --> UAA
        BSPN --> ContribSub
        BSPN --> ContribRG
    end
```

---

## Managed identity authentication

The App Service and Function App both use **system-assigned managed identities** for all Azure service authentication. No connection strings, no stored credentials.

| Service | Auth type | MI |
|---|---|---|
| Azure SQL | `azure-active-directory-msi-app-service` | App Service MI |
| Key Vault | MI credential via `@azure/identity` DefaultAzureCredential | App Service MI |
| ARM (read) | MI credential | App Service MI |
| Key Vault | MI credential | Function App MI |
| ARM (read + recommendations) | MI credential | Function App MI |

---

## Bootstrap SPN (CI/CD only)

The `bootstrap-capdash` SPN is used only by GitHub Actions for infrastructure deployment. It is **never used at runtime**.

OIDC federated credentials are configured for three subjects:

| Subject | Used by |
|---|---|
| `ref:refs/heads/main` | Pushes to main branch |
| `pull_request` | PR validation workflows |
| `repo:{org}/{repo}:environment:production` | The `bicep-deploy.yml` `environment: production` job |

The bootstrap SPN requires elevated roles (`User Access Administrator` at subscription) to deploy RBAC role assignments via Bicep. This is scoped to the minimum needed.

!!! tip
    The bootstrap script (`scripts/bootstrap-github-oidc.ps1`) handles SPN creation, role grants, and federated credential configuration automatically. See [Bootstrap Guide](../deployment/bootstrap.md).
