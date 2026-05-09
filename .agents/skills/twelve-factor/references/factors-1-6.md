# 12-Factor App — Factors 1–6

## Factor 1: Codebase

**One codebase tracked in version control; many deploys from one repo.**

- [ ] Single Git repository per application
- [ ] All code tracked in Git (no loose files, no manual production changes)
- [ ] Multiple deployments (prod, staging, dev) use the same codebase — only config differs

```
❌ Multiple repos for the same app
❌ Manual file changes directly on production
✅ Same repo → prod, staging, dev (only env vars change)
```

## Factor 2: Dependencies

**Explicitly declare and isolate all dependencies.**

```bash
# Node.js — package-lock.json in repo
# Python — requirements.txt or Pipfile.lock
# Go — go.mod + go.sum
# .NET — packages.lock.json
```

```bash
# ✅ Use containers or virtual environments
docker build .
python -m venv .venv && pip install -r requirements.txt

# ❌ Never rely on system-installed packages
apt-get install python3-pandas  # Not reproducible
```

## Factor 3: Config

**Store config in the environment, not in code.**

```python
# ✅ Read from environment
import os
DB_URL = os.environ['DB_URL']
API_KEY = os.environ['API_KEY']

# ❌ Never hardcode
API_KEY = "abc123"  # committed to Git = credential leak
```

```bash
# Local dev only — .env file in .gitignore
DB_HOST=localhost
DB_USER=admin
```

## Factor 4: Backing Services

**Treat databases, caches, queues as attached resources — swappable via config.**

```python
# ✅ URL comes from env — swap production → staging with one env var change
import pymongo
client = pymongo.MongoClient(os.environ['MONGODB_URL'])
```

**Backing Services Checklist**

- [ ] Database — connection string via env var
- [ ] Cache (Redis) — URL via env var
- [ ] Message queue — broker address via env var
- [ ] Email service — API key via env var
- [ ] File storage — bucket name via env var

## Factor 5: Build, Release, Run

**Strictly separate build, release, and run stages.**

```
Code
  ↓ Build stage: compile, test, create artifact (Docker image, JAR, zip)
  ↓ Release stage: combine artifact + environment config (immutable release)
  ↓ Run stage: execute the release (process start, no code changes)
```

```dockerfile
# Build stage
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test && npm run build

# Run stage (immutable artifact)
FROM node:20-slim
WORKDIR /app
COPY --from=build /app/dist ./dist
ENV PORT=8080
CMD ["node", "dist/server.js"]
```

- Never modify code at runtime — patch the source, rebuild, redeploy
- Every release gets a unique ID (Git SHA or semantic version)

## Factor 6: Processes

**Execute the app as one or more stateless, share-nothing processes.**

- [ ] No in-memory session state (use Redis or a database)
- [ ] No local file uploads (use object storage: S3, Azure Blob)
- [ ] No sticky sessions (load balancer routes any request to any process)

```python
# ❌ In-memory state — lost on process restart
sessions = {}
sessions[user_id] = {"name": "Alice"}

# ✅ Persistent state
redis.setex(f"session:{user_id}", 3600, json.dumps({"name": "Alice"}))
```
