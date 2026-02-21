# Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the ShopMicro platform to a Kubernetes cluster.

## Prerequisites
- A running Kubernetes cluster (v1.25+)
- `kubectl` installed and configured
- `docker` installed (for building images)
- `terraform` installed (for infrastructure)
- **AWS EBS CSI Driver** installed (mandatory for EKS storage)

## 0. Infrastructure Provisioning (Terraform)
Before deploying the application, you need a Kubernetes cluster. You can provision the necessary EC2 instances (Master & Worker nodes) using Terraform.

1. **Navigate to the Terraform directory:**
   ```bash
   cd infrastructure/terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Check and Update Configuration:**
   - Open `variables.tf` and ensure `key_name` matches your AWS Key Pair.
   - You can also create a `terraform.tfvars` file to override defaults.

4. **Provision Infrastructure:**
   ```bash
   terraform apply
   ```
   *Type `yes` to confirm.*

5. **Note the Output IPs:**
   Terraform will output the `master_public_ip` and `worker_public_ip`. Use these to SSH into your instances and install Kubernetes (e.g., using kubeadm or k3s).

   *Once your cluster is running and `kubectl` is configured to point to it, proceed to step 1.*

## 1. Build and Push Images
(Skipped for local development if using Minikube with `eval $(minikube docker-env)`)

```bash
# Example for each service
docker build -t your-registry/shopmicro-backend:latest ./backend
docker push your-registry/shopmicro-backend:latest

docker build -t your-registry/shopmicro-ml-service:latest ./ml-service
docker push your-registry/shopmicro-ml-service:latest

docker build -t your-registry/shopmicro-frontend:latest ./frontend
docker push your-registry/shopmicro-frontend:latest
```

*Note: Update the image names in `k8s/*.yaml` files to match your registry.*

## 2. Deploy to Kubernetes

### Step 1: Create Namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

### Step 2: Deploy Secrets (Manual Step)
Create the database credentials secret:
```bash
kubectl create secret generic db-credentials \
  --namespace shopmicro \
  --from-literal=username=postgres \
  --from-literal=password=postgres
```

### Step 3: Deploy ConfigMaps (Manual Step for Init SQL)
```bash
kubectl create configmap postgres-init \
  --namespace shopmicro \
  --from-file=init.sql=postgres/init.sql
```

### Step 4: Deploy All Manifests
```bash
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/ml-service.yaml
kubectl apply -f k8s/frontend.yaml
```

### Step 5: Configure Ingress
```bash
kubectl apply -f k8s/ingress.yaml
```

### Step 6: Deploy Observability Stack
```bash
# Apply LGTM Stack + OTel
kubectl apply -f k8s/observability/prometheus.yaml
kubectl apply -f k8s/observability/loki.yaml
kubectl apply -f k8s/observability/tempo.yaml
kubectl apply -f k8s/observability/otel-collector.yaml

# Apply Grafana Configs (Datasources & Dashboards)
kubectl apply -f k8s/observability/grafana-datasources.yaml
kubectl apply -f k8s/observability/dashboards.yaml
kubectl apply -f k8s/observability/prometheus-rules.yaml

# Deploy Grafana
kubectl apply -f k8s/grafana.yaml
```

*Access Grafana at `http://<node-ip>:3000` (NodePort) or via Ingress if configured.*
*Default Login: admin / admin*


## 3. Operations

### Check Status
```bash
kubectl get pods -n shopmicro
kubectl get svc -n shopmicro
```

### Restart a Service
```bash
kubectl rollout restart deployment/backend -n shopmicro
```

### View Logs
```bash
kubectl logs -l app=backend -n shopmicro
```
