# Final Capstone Assignment: ShopMicro Production Platform (Self-Contained)

## 1. Scenario
Your team is the Platform Engineering squad for **ShopMicro**, a microservices e-commerce system with:
- Frontend (React)
- Backend API (Node.js/Express)
- ML recommendation service (Python/Flask)
- PostgreSQL + Redis

You must deliver a production-style platform that is reproducible, observable, secure, and automated end-to-end.

## 2. Goal
Build, deploy, and operate ShopMicro using a complete DevOps/Platform Engineering toolchain:
- Docker and Docker Compose
- Kubernetes (scheduling, networking, lifecycle, security, storage, troubleshooting)
- Observability (metrics, logs, traces, dashboards)
- IaC/CaC (Terraform + Ansible on AWS patterns)
- CI/CD with quality gates, policy-as-code, and drift checks
- DevOps scripting/tooling (Go or shell automation)

## 3. Requirements

### A. Application and Containerization
1. Containerize all services with optimized Dockerfiles.
2. Provide local development orchestration via Docker Compose.
3. Ensure service-to-service networking and environment configuration work without manual edits.

### B. Kubernetes Platform
1. Deploy all app services into a dedicated namespace.
2. Use ConfigMaps and Secrets (no hardcoded secrets in manifests).
3. Expose the application through Ingress.
4. Apply scheduling controls:
   - node labels/selectors or affinity
   - taints/tolerations where appropriate
   - anti-affinity for at least one replicated service
5. Use rolling updates and demonstrate rollback.
6. Include persistent storage for PostgreSQL (PVC/StorageClass).
7. Add resource requests/limits and basic autoscaling strategy (HPA or documented policy).

### C. Observability (LGTM + OTel)
1. Implement metrics, logs, and traces for backend and ML service.
2. Deploy/use Grafana + Mimir/Prometheus-compatible metrics, Loki, Tempo, Alloy/collector config.
3. Provide at least 3 dashboards:
   - platform overview
   - backend/service health
   - logs/traces correlation
4. Define 3 SLIs and 2 SLOs (with rationale).
5. Add at least 2 actionable alerts.

### D. IaC and Configuration as Code
1. Use Terraform to define infrastructure architecture (real cloud or realistic module-structured design):
   - network
   - compute/runtime layer
   - data layer
   - security boundaries
2. Structure code as reusable modules.
3. Use remote state design and locking approach (implemented or clearly documented if sandboxed).
4. Use Ansible roles to configure hosts/services and prove idempotency.

### E. CI/CD and Quality Gates
1. Implement pipeline stages for:
   - lint/format
   - unit/integration tests
   - build and image publish strategy
   - deploy workflow (dev at minimum)
2. Add IaC testing pyramid elements:
   - static checks (`terraform validate`, linting)
   - at least one Terraform test
   - policy-as-code check (OPA/Rego or equivalent)
3. Add drift-detection workflow (scheduled or on-demand).

### F. Security and Reliability
1. Enforce least-privilege network paths.
2. Encrypt secrets at rest/in transit strategy (implemented or explicitly documented).
3. No public SSH exposure by default.
4. Provide backup/restore approach for stateful components.
5. Include incident runbook for one simulated outage.

### G. DevOps Tooling
Create one CLI utility (Go preferred, shell acceptable) that automates an operational task, e.g.:
- environment health validation
- release verification
- evidence collection for grading

## 4. Deliverables
Submit one repository folder containing:
1. `README.md` with architecture diagram, assumptions, and quick-start.
2. `docker/` and/or `docker-compose.yml` assets.
3. `k8s/` manifests (or Helm values + manifests).
4. `infrastructure/terraform/` and `infrastructure/ansible/`.
5. `.github/workflows/` (or equivalent CI pipeline definitions) with comments explaining each stage.
6. `observability/` configs + dashboard JSON exports.
7. `runbooks/` with incident and recovery guide.
8. `evidence/` containing:
   - deployment outputs
   - test results
   - dashboard screenshots
   - rollback proof

## 5.1 Required README Sections (Mandatory)
Your `README.md` must include all sections below so no extra handout is required:
1. Problem statement and architecture summary
2. High-level architecture diagram (ASCII or image)
3. Prerequisites and tooling versions
4. Exact deploy commands
5. Exact test/verification commands
6. Observability usage guide (how to view metrics/logs/traces)
7. Rollback procedure
8. Security controls implemented
9. Backup/restore procedure
10. Known limitations and next improvements

## 6. Constraints
- No manual cloud-console-only steps for core deployment.
- No plaintext production secrets in git.
- Everything required for deployment must be scripted or documented as reproducible commands.

## 7. Suggested Execution Plan
1. Foundation setup (containers + local compose)
2. Kubernetes deployment and networking
3. Observability instrumentation and dashboards
4. Terraform/Ansible structure and environment promotion
5. CI/CD and policy gates
6. Security hardening and resilience validation
7. Final demo + documentation

## 8. Evaluation Rubric (100 points)
- Architecture and deployment completeness: 20
- Kubernetes correctness and operations readiness: 20
- Observability depth (metrics/logs/traces + SLO thinking): 15
- IaC/CaC design quality and reusability: 15
- CI/CD quality gates and policy enforcement: 15
- Security/reliability/runbooks: 10
- DevOps tooling utility and code quality: 5

## 9. Demo Checklist
- One-command deployment path works
- App reachable through ingress/load balancer
- Telemetry visible in Grafana dashboards
- Triggered failure detected by alerts
- Rollback successfully executed
- Evidence bundle complete

## 10. Submission Format
Package your submission as:
- Source repository (all code and configs)
- A single PDF or Markdown report named `CAPSTONE_REPORT` summarizing outcomes and linking evidence
- Optional short demo video (5-10 minutes)

## 11. Timebox
- Recommended: **16-24 hours total** over 4-6 working sessions.

## 12. Appendix: Minimal Sample Working Code (Optional Starter)
Use this only as a baseline if you need a quick starting point. You are expected to improve and productionize it.

### 12.1 `backend/server.js`
```javascript
const express = require("express");
const { Pool } = require("pg");
const redis = require("redis");

const app = express();
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST || "postgres",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "shopmicro",
  port: Number(process.env.DB_PORT || 5432),
});

const cache = redis.createClient({
  url: process.env.REDIS_URL || "redis://redis:6379",
});
cache.connect().catch(() => {});

app.get("/health", async (_req, res) => {
  res.json({ status: "ok", service: "backend" });
});

app.get("/products", async (_req, res) => {
  try {
    const cached = await cache.get("products");
    if (cached) return res.json(JSON.parse(cached));
    const result = await pool.query("SELECT id, name, price FROM products ORDER BY id");
    await cache.setEx("products", 30, JSON.stringify(result.rows));
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "backend_error", detail: err.message });
  }
});

app.listen(8080, () => console.log("backend listening on 8080"));
```

### 12.2 `backend/package.json`
```json
{
  "name": "shopmicro-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.12.0",
    "redis": "^4.6.15"
  }
}
```

### 12.3 `ml-service/app.py`
```python
from flask import Flask, jsonify, request
import random

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "ml-service"})

@app.get("/recommendations/<int:user_id>")
def recommendations(user_id: int):
    catalog = ["keyboard", "monitor", "headset", "mouse", "webcam"]
    random.seed(user_id)
    picks = random.sample(catalog, 3)
    return jsonify({"user_id": user_id, "recommendations": picks})

@app.get("/metrics")
def metrics():
    # Minimal placeholder so scraping does not fail in starter mode
    return "shopmicro_ml_requests_total 1\n", 200, {"Content-Type": "text/plain; version=0.0.4"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### 12.4 `ml-service/requirements.txt`
```txt
flask==3.0.3
```

### 12.5 `frontend/src/App.jsx`
```jsx
import { useEffect, useState } from "react";

const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:8080";
const ML_BASE = import.meta.env.VITE_ML_BASE || "http://localhost:5000";

export default function App() {
  const [products, setProducts] = useState([]);
  const [recs, setRecs] = useState([]);

  useEffect(() => {
    fetch(`${API_BASE}/products`).then(r => r.json()).then(setProducts).catch(() => setProducts([]));
    fetch(`${ML_BASE}/recommendations/42`).then(r => r.json()).then(d => setRecs(d.recommendations || [])).catch(() => setRecs([]));
  }, []);

  return (
    <main style={{ fontFamily: "sans-serif", maxWidth: 720, margin: "2rem auto" }}>
      <h1>ShopMicro</h1>
      <h2>Products</h2>
      <ul>{products.map(p => <li key={p.id}>{p.name} - ${p.price}</li>)}</ul>
      <h2>Recommended for User 42</h2>
      <ul>{recs.map(r => <li key={r}>{r}</li>)}</ul>
    </main>
  );
}
```

### 12.6 `postgres/init.sql`
```sql
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL
);

INSERT INTO products (name, price) VALUES
('Mechanical Keyboard', 79.99),
('4K Monitor', 299.99),
('USB-C Dock', 129.99)
ON CONFLICT DO NOTHING;
```

### 12.7 Minimal Dockerfiles
`backend/Dockerfile`
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
```

`ml-service/Dockerfile`
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

### 12.8 `docker-compose.yml`
```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: shopmicro
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports: ["5432:5432"]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  backend:
    build: ./backend
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: shopmicro
      REDIS_URL: redis://redis:6379
    depends_on: [postgres, redis]
    ports: ["8080:8080"]

  ml-service:
    build: ./ml-service
    ports: ["5000:5000"]

  frontend:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./frontend:/app
    command: sh -c "npm install && npm run dev -- --host 0.0.0.0 --port 3000"
    environment:
      VITE_API_BASE: http://backend:8080
      VITE_ML_BASE: http://ml-service:5000
    depends_on: [backend, ml-service]
    ports: ["3000:3000"]
```

### 12.9 Minimal Kubernetes Starter (`k8s/`)
`k8s/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: shopmicro
```

`k8s/backend.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: shopmicro
spec:
  replicas: 2
  selector:
    matchLabels: { app: backend }
  template:
    metadata:
      labels: { app: backend }
    spec:
      containers:
      - name: backend
        image: your-registry/shopmicro-backend:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: shopmicro
spec:
  selector: { app: backend }
  ports:
  - port: 8080
    targetPort: 8080
```

`k8s/ml-service.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-service
  namespace: shopmicro
spec:
  replicas: 1
  selector:
    matchLabels: { app: ml-service }
  template:
    metadata:
      labels: { app: ml-service }
    spec:
      containers:
      - name: ml-service
        image: your-registry/shopmicro-ml:latest
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: ml-service
  namespace: shopmicro
spec:
  selector: { app: ml-service }
  ports:
  - port: 5000
    targetPort: 5000
```
