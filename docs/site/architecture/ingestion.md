# Ingestion Pipeline

The ingestion pipeline pulls live Azure capacity and quota data from ARM and stores it in Azure SQL. It runs on a schedule and can be triggered on demand via the Admin panel.

---

## Pipeline architecture

```mermaid
flowchart LR
    classDef trigger fill:#fff7ed,stroke:#ea580c
    classDef step fill:#dbeafe,stroke:#2563eb
    classDef sink fill:#f3e8ff,stroke:#7c3aed
    classDef source fill:#f1f5f9,stroke:#64748b

    Timer[Timer Trigger\nevery N hours]:::trigger
    Admin[Admin Panel\nor API call]:::trigger

    subgraph FuncApp["Function App — PowerShell 7.4"]
        RunCap[Run-CapacityIngest\nHttpTrigger]:::step
        FetchSKU[Fetch VM SKU availability\nper region × subscription]:::step
        FetchQuota[Fetch compute quota\nper region × subscription]:::step
        Score[Compute placement\nrecommendation score]:::step
        UpsertSQL[Upsert CapacitySnapshot\n+ update ingestion log]:::step
    end

    ARM["Azure ARM\nCompute.virtualMachines/skus\nCompute.usages"]:::source
    SQL[(Azure SQL\nCapacitySnapshot\nIngestionLog)]:::sink

    Timer -->|POST /ingest/capacity\nHMAC signed| RunCap
    Admin -->|POST /internal/ingest\nHMAC signed| RunCap
    RunCap --> FetchSKU
    RunCap --> FetchQuota
    FetchSKU --> ARM
    FetchQuota --> ARM
    ARM --> Score
    Score --> UpsertSQL
    UpsertSQL --> SQL
```

---

## AI model catalog ingestion

A separate pipeline ingests Azure OpenAI and AI Foundry model availability.

```mermaid
flowchart LR
    classDef step fill:#dcfce7,stroke:#16a34a
    classDef source fill:#f1f5f9,stroke:#64748b
    classDef sink fill:#f3e8ff,stroke:#7c3aed

    ARM_AI["Azure ARM\nCognitive Services / AI Foundry\nmodel catalog endpoints"]:::source
    FetchAI[Fetch AI model availability\nper region × subscription]:::step
    UpsertAI[Upsert AIModelAvailability]:::step
    SQL[(Azure SQL\nAIModelAvailability)]:::sink

    ARM_AI --> FetchAI --> UpsertAI --> SQL
```

---

## Ingestion schedule

| Dataset | Default schedule | Configurable via |
|---|---|---|
| VM capacity snapshots | Every 6 hours | `INGEST_INTERVAL_HOURS` env var |
| AI model catalog | Once per day | `AI_INGEST_INTERVAL_HOURS` env var |
| Live placement (on-demand) | Per user request | No schedule — triggered per call |

---

## Triggering ingestion manually

From the Admin panel → **Ingestion** → **Run Now**.

Or via the internal API (requires `INGEST_API_KEY`):

```bash
curl -X POST https://<host>/internal/ingest/capacity \
  -H "x-ingest-api-key: <INGEST_API_KEY>"
```

---

## Data freshness

The `CapacitySnapshot` table stores one row per `(subscriptionId, region, vmSku)`. Each row has a `snapshotTime` column. The UI displays the most recent snapshot time in the filter bar.

!!! tip
    If capacity data looks stale, check the **Ingestion Log** in the Admin panel for recent run status and error details.
