# Architecture Overview

The dashboard is a three-tier Node.js web application backed by Azure SQL, with a PowerShell Azure Functions worker for compute-intensive ARM calls.

---

## System Context (C4 Level 1)

Who uses the system and what external services does it depend on.

```mermaid
C4Context
    title Capacity Planning Dashboard — System Context

    Person(user, "Platform / Capacity Team", "Browses capacity, manages quotas, triggers ingestion")
    Person(admin, "Dashboard Admin", "Manages ingestion schedules, views error logs, submits quota requests")

    System(dashboard, "Capacity Planning Dashboard", "Web UI + REST API. Visualises Azure VM capacity, quota headroom, and AI model availability.")

    System_Ext(arm, "Azure Resource Manager", "VM SKU availability, quota APIs, management group hierarchy")
    System_Ext(entra, "Microsoft Entra ID", "Authentication and group-based authorisation")
    System_Ext(appi, "Application Insights", "Telemetry, distributed tracing, exception tracking")

    Rel(user, dashboard, "Uses", "HTTPS")
    Rel(admin, dashboard, "Administers", "HTTPS")
    Rel(dashboard, arm, "Reads capacity & quota data\nSubmits quota requests", "HTTPS / ARM SDK")
    Rel(dashboard, entra, "Authenticates users\nChecks group membership", "OIDC / MSAL")
    Rel(dashboard, appi, "Sends telemetry", "SDK")
```

---

## Container Diagram (C4 Level 2)

The internal components and how they connect.

```mermaid
flowchart TB
    classDef azure fill:#dbeafe,stroke:#2563eb,color:#1e3a5f
    classDef worker fill:#dcfce7,stroke:#16a34a,color:#14532d
    classDef data fill:#f3e8ff,stroke:#7c3aed,color:#3b0764
    classDef infra fill:#fff7ed,stroke:#ea580c,color:#431407
    classDef external fill:#f1f5f9,stroke:#64748b,color:#1e293b

    Browser[Browser\nReact UI / Classic HTML]

    subgraph AppService["App Service (app-capdash-prod)"]
        direction TB
        API[Express API\nNode.js 20\nSystem-assigned MI]
    end

    subgraph FunctionApp["Function App (worker)"]
        direction TB
        Worker[PowerShell 7.4 worker\nCapacity recommendations\nLive placement scoring\nSystem-assigned MI]
    end

    SQL[(Azure SQL Database\nCapacitySnapshot\nAIModelAvailability\nDashboardSetting\nAppSessions)]
    KV[Azure Key Vault\nSession secret\nIngest API key\nWorker shared secret]
    APPI[Application Insights]
    ARM[Azure ARM / Quota APIs]
    Entra[Microsoft Entra ID]

    Browser -->|HTTPS| API
    API -->|MI auth / mssql| SQL
    API -->|Key Vault ref| KV
    API -->|Shared secret| Worker
    API -->|ARM SDK\nReader role| ARM
    API -->|MSAL auth-code flow| Entra
    Worker -->|ARM SDK\nCompute Recommendations role| ARM
    Worker -->|Key Vault ref| KV
    API --> APPI
    Worker --> APPI

    class API azure
    class Worker worker
    class SQL data
    class KV,APPI infra
    class ARM,Entra external
```

---

## Data flow summary

```mermaid
sequenceDiagram
    participant U as User Browser
    participant API as App Service (API)
    participant SQL as Azure SQL
    participant W as Function App (Worker)
    participant ARM as Azure ARM

    Note over API,ARM: Ingestion (scheduled or admin-triggered)
    API->>W: POST /ingest/capacity (shared secret)
    W->>ARM: List SKU availability per region/sub
    ARM-->>W: Capacity data
    W->>SQL: Upsert CapacitySnapshot rows
    W-->>API: { ok: true, rowsWritten: N }

    Note over U,SQL: Read path
    U->>API: GET /api/capacity?regionPreset=USMajor&family=Standard_D
    API->>SQL: SELECT from CapacityLatest (indexed view)
    SQL-->>API: Capacity rows
    API-->>U: { rows: [...] }

    Note over U,ARM: Quota apply
    U->>API: POST /api/quota/apply (admin only)
    API->>ARM: Submit quota increase request
    ARM-->>API: Request ID
    API-->>U: { jobId: "..." }
```
