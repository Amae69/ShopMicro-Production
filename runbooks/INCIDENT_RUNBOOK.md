# Incident Runbook: Database Connection Failure

**Severity**: P1 (Critical)  
**Symptom**: Frontend shows "500 Internal Server Error" or Backend logs show "Connection refused" when connecting to PostgreSQL.

## 🚩 Detection
- **Alert**: Grafana shows a spike in "Backend Error" metrics.
- **Manual Check**:
  ```bash
  kubectl get pods -l app=postgres -n shopmicro
  ```

## 🛠️ Triage & Resolution

### Step 1: Check Pod Status
If the pod is not `Running`:
```bash
kubectl describe pod -l app=postgres -n shopmicro
```
- **Error: `CrashLoopBackOff`**: Check logs (`kubectl logs -l app=postgres -n shopmicro`). Common cause: `PGDATA` corruption or volume mismatch.
- **Error: `Pending`**: Check PVC status (`kubectl get pvc -n shopmicro`). Common cause: EBS CSI Driver failure.

### Step 2: Test Network Connectivity
Verify the backend can reach the postgres service:
```bash
BACKEND_POD=$(kubectl get pods -l app=backend -n shopmicro -o jsonpath='{.items[0].metadata.name}')
kubectl exec $BACKEND_POD -n shopmicro -- nc -zv postgres 5432
```

### Step 3: Check Database Readiness
If the pod is running but connection is refused, check if Postgres is initialized:
```bash
kubectl logs -l app=postgres -n shopmicro --tail=50
```

### Step 4: Emergency Recovery
If the database state is corrupted beyond repair, trigger the **Restore Procedure** in `runbooks/POSTGRES_BACKUP_RESTORE.md`.

## 📈 Post-Mortem
1. Identify the root cause (e.g., node failure, volume detach).
2. Update HPA/Anti-affinity rules if necessary.
3. Verify monitoring alerts fired correctly.
