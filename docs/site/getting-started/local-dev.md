# Local Development

Get the dashboard running on your laptop in under 10 minutes.

---

## 1. Clone and install

```bash
git clone https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard.git
cd Capacity-Planning-Dashboard
npm install
```

---

## 2. Start a local SQL Server

The repo ships a `docker-compose.yml` for a local SQL Server 2022 instance:

```bash
docker compose up -d
```

This starts SQL Server on port **1433** with:

- SA password: `DevLocalPa$$w0rd1`
- Persistent data volume: `mssql-data`

Wait ~15 seconds for the server to initialise, then verify:

```bash
docker compose ps   # should show "healthy"
```

---

## 3. Configure your environment

Copy the sample env file:

```bash
cp .env.example .env
```

Edit `.env` with these minimum values for local dev (no auth, local SQL):

```dotenv
# Server
PORT=3000
NODE_ENV=development

# Disable Entra auth for local dev
AUTH_ENABLED=false

# Local SQL (Docker)
SQL_SERVER=localhost
SQL_DATABASE=CapacityDashboard
SQL_AUTH_MODE=sql
SQL_USER=sa
SQL_PASSWORD=DevLocalPa$$w0rd1
SQL_TRUST_SERVER_CERTIFICATE=true

# Ingestion - uses Azure CLI credential when running locally
INGEST_SUBSCRIPTION_IDS=<your-sub-id>   # optional, auto-discovers if empty

# Quota (optional)
QUOTA_MANAGEMENT_GROUP_ID=             # your mgmt group ID or leave empty
```

!!! note "Never commit `.env`"
    `.env` is in `.gitignore`. Only `.env.example` is committed.

---

## 4. Run migrations

```bash
npm run migrate
```

This creates the `CapacityDashboard` database and schema on your local SQL instance.

---

## 5. Start the server

```bash
npm start
```

Open [http://localhost:3000](http://localhost:3000) — the dashboard loads in unauthenticated mode.

---

## 6. Trigger a local ingestion (optional)

With the server running and `AZURE_SUBSCRIPTION_IDS` set:

```bash
curl -X POST http://localhost:3000/internal/ingest/capacity \
  -H "x-ingest-api-key: local-dev-key"
```

This pulls live VM SKU data from ARM using your `az login` credential and populates the local SQL database.

---

## Troubleshooting local setup

| Symptom | Likely cause | Fix |
|---|---|---|
| `ECONNREFUSED localhost:1433` | SQL container not running | `docker compose up -d` |
| `Login failed for user 'sa'` | Wrong password or SQL not ready | Wait 15s and retry |
| `Failed to retrieve family summary` | No ingestion data | Run ingestion step above |
| `/api/quota/management-groups: Failed` | `QUOTA_MANAGEMENT_GROUP_ID` empty or wrong | Set a valid management group ID |
| Auth redirect loop | `AUTH_ENABLED=true` but Entra not configured | Set `AUTH_ENABLED=false` for local dev |
