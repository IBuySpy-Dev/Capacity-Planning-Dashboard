# Deployment Topology

---

## Azure resource topology

```mermaid
flowchart TB
    classDef az fill:#dbeafe,stroke:#2563eb
    classDef net fill:#dcfce7,stroke:#16a34a
    classDef sec fill:#fff7ed,stroke:#ea580c

    subgraph Sub["Azure Subscription"]
        subgraph RG["Resource Group: rg-capdash-prod"]
            subgraph VNet["VNet: vnet-capdash-prod"]
                subgraph AppSubnet["Subnet: snet-app"]
                    WebApp[App Service\napp-capdash-prod]:::az
                end
                subgraph FuncSubnet["Subnet: snet-func"]
                    FuncApp[Function App\nfunc-capdash-worker]:::az
                end
                subgraph DataSubnet["Subnet: snet-data"]
                    SQL[(Azure SQL\ncapdash-prod/CapacityDashboard)]:::az
                end
            end
            KV[Key Vault\nkv-capdash-prod]:::sec
            APPI[Application Insights\nappi-capdash-prod]:::az
            ASP[App Service Plan\nasp-capdash-prod\nB2 Linux]:::az
        end
    end

    WebApp -->|Private Endpoint| SQL
    FuncApp -->|Private Endpoint| SQL
    WebApp -->|Private Endpoint| KV
    FuncApp -->|Private Endpoint| KV
```

---

## CI/CD pipeline

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub Actions
    participant AZ as Azure (ARM)
    participant APP as App Service / Function App

    Dev->>GH: git push → main branch

    Note over GH: bicep-deploy.yml triggers

    GH->>GH: az login (OIDC fedcred)
    GH->>AZ: az deployment group create\n--template-file infra/bicep/main.bicep

    AZ->>AZ: Provision / update resources\n(idempotent, ARM handles drift)
    AZ-->>GH: Deployment outputs\n(webAppName, functionAppName, ...)

    GH->>APP: az webapp deploy\n--src-path dist.zip
    GH->>APP: az functionapp deployment\n--src-path worker.zip

    GH->>APP: az webapp config appsettings set\n(push Key Vault refs, APPI connection, etc.)

    APP-->>GH: Deployment complete

    Note over GH: Health check — GET /healthz
    GH->>APP: GET https://{webAppUrl}/healthz
    APP-->>GH: 200 { status: ok }
```

---

## Environments

| Environment | Branch | Infra | Bicep parameter file |
|---|---|---|---|
| `production` | `main` | `rg-capdash-prod` | `infra/bicep/params/prod.bicepparam` |

!!! info
    A staging environment is not yet provisioned. PRs run Bicep `what-if` only.
