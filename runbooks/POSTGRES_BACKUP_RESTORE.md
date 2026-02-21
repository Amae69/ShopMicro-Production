# PostgreSQL Backup and Restore Runbook

This guide outlines the strategy for ensuring data durability for the ShopMicro platform's PostgreSQL database.

## 💾 Backup Strategy

### 1. Manual Backup (pg_dump)
Perform a manual backup of the `shopmicro` database:

```bash
# Get the postgres pod name
POD_NAME=$(kubectl get pods -l app=postgres -n shopmicro -o jsonpath='{.items[0].metadata.name}')

# Execute pg_dump and save locally
kubectl exec $POD_NAME -n shopmicro -- pg_dump -U postgres shopmicro > shopmicro_backup_$(date +%Y%m%d).sql
```

### 2. Automated Backups (Recommended)
On AWS EKS, use **AWS Backup** to take daily snapshots of the EBS volumes associated with the `postgres` PersistentVolumeClaim.

---

## 🔄 Restore Procedure

### 1. Restore from SQL Dump
To restore data into a running Postgres instance:

```bash
# Copy the backup file to the pod
kubectl cp shopmicro_backup.sql $POD_NAME:/tmp/backup.sql -n shopmicro

# Execute restore
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres shopmicro -f /tmp/backup.sql
```

### 2. Restore from Volume Snapshot
1. Create a new `PersistentVolumeClaim` from the latest EBS snapshot.
2. Update `k8s/postgres.yaml` to point to the new PVC.
3. Re-apply the manifest: `kubectl apply -f k8s/postgres.yaml`.

---

## ✅ Verification
After restoration, verify the data integrity:
```bash
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres shopmicro -c "SELECT count(*) FROM products;"
```
