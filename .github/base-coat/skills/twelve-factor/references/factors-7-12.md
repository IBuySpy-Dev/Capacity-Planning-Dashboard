# 12-Factor App — Factors 7–12

## Factor 7: Port Binding

**Export HTTP service via port binding — the app is self-contained.**

The app does not rely on an external web server (Apache, IIS). It binds a port and
listens directly.

```python
from flask import Flask
import os

app = Flask(__name__)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

```yaml
# Kubernetes: expose the app's own port
spec:
  containers:
  - name: app
    image: my-app:v1.0.0
    ports:
    - containerPort: 8080
```

## Factor 8: Concurrency

**Scale out via the process model — add more processes, not bigger processes.**

```
Web tier:   5 × web process (handles HTTP requests)
Worker tier: 2 × worker process (handles background jobs)
Scheduler:  1 × clock process (handles scheduled tasks)
```

- Horizontal scaling: start more identical processes
- Never add threads to handle concurrency that could be handled with more processes
- Processes should be interchangeable — any process can handle any request

## Factor 9: Disposability

**Fast startup, graceful shutdown, resilience to sudden death.**

**Fast startup target:** < 10 seconds.
**Graceful shutdown:** handle SIGTERM; finish in-flight requests; close connections.

```python
import signal, sys

def graceful_shutdown(signum, frame):
    # Finish current requests, close DB connections
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
```

```yaml
# Kubernetes: drain connections before stop
spec:
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]
```

**Worker jobs:** use a queue with visibility timeout; on crash, job becomes visible again and
another worker picks it up — no job loss.

## Factor 10: Dev/Prod Parity

**Keep all environments as identical as possible.**

| Aspect | Dev | Prod | Parity |
|---|---|---|---|
| OS | Ubuntu 22.04 | Ubuntu 22.04 | ✅ |
| Language | Python 3.12 | Python 3.12 | ✅ |
| DB | PostgreSQL 16 | PostgreSQL 16 | ✅ |
| Deploy method | Docker Compose | Docker / K8s | ✅ |

```yaml
# docker-compose.yml mirrors production services
services:
  app:
    build: .
    ports: ["8080:8080"]
    environment:
      DB_HOST: postgres
      DB_USER: admin
      DB_PASSWORD: devpass
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: devpass
```

**Common parity mistakes:**

- Using SQLite in dev, PostgreSQL in prod — different SQL behavior
- Using a stub email service in dev, SendGrid in prod — different failure modes
- Different OS in CI vs prod — library version differences

## Factor 11: Logs

**Treat logs as event streams — write to stdout only, never manage logfiles.**

```python
# ✅ Write to stdout (Docker/Kubernetes captures this)
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("User login", extra={"user_id": user_id})

# ❌ Write to files (ephemeral container storage, not searchable)
handler = logging.FileHandler('/var/log/app.log')
```

```
App → stdout
  ↓ Docker/Kubernetes captures container stdout
  ↓ Log aggregation: ELK, Datadog, Azure Monitor, Loki
  ↓ Searchable dashboard + alerts
```

## Factor 12: Admin Tasks

**Run one-off admin tasks (migrations, scripts) in the same environment as the app.**

```python
# migrations/001_add_email_verified.py — same image, same config
import os
from app import db

db.connect(os.environ['DB_URL'])
db.execute("ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE")
```

```bash
# Docker: same image, different entrypoint
docker run my-app:v1.0.0 python migrations/001_add_email_verified.py

# Kubernetes: one-off Job
kubectl run migration --restart=Never --image=my-app:v1.0.0 \
  -- python migrations/001_add_email_verified.py
```

- Never run admin tasks against prod using a different version than what is deployed
- Include admin scripts in the app repo (same CI, same tests)
- Use idempotent migrations — safe to re-run if the task is interrupted
