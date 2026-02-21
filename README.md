# ShopMicro - E-commerce Microservices Platform

## 1. Problem Statement and Architecture Summary
ShopMicro is a cloud-native e-commerce platform designed to demonstrate a robust DevOps and Platform Engineering toolchain. The objective is to provide a scalable, secure, and observable environment for microservices.
- **Frontend**: React/Vite (Nginx)
- **Backend API**: Node.js/Express
- **ML Service**: Python/Flask (Recommendations)
- **Data Store**: PostgreSQL (StatefulSet) & Redis (Cache)
- **Infrastructure**: AWS EKS,AWS EC2 provisioned via Terraform and k8s cluster configured in Ec2 via Ansible.

## 2. High-Level Architecture Diagram
![ShopMicro Architecture](./images/architecture.png)

## 3. Prerequisites and Tooling Versions
- **Kubernetes**: v1.25+ (Targeted for AWS EKS)
- **kubectl**: v1.27+
- **Terraform**: v1.5.0+
- **AWS CLI**: v2.11+
- **Node.js**: v20.x
- **Python**: v3.12+
- **Docker**: v24.x+

## 4. Exact Deploy Commands

### A. Infrastructure (Terraform)
```bash
cd infrastructure/terraform
terraform init
terraform apply -auto-approve
```

### B. Kubernetes Deployment
```bash
# 1. Namespace & Secrets
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml.template

# 2. Data Layer
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/postgres.yaml

# 3. Application Services
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/ml-service.yaml
kubectl apply -f k8s/frontend.yaml

# 4. Access Control (Ingress)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
kubectl apply -f k8s/ingress.yaml

# 5. Scaling & Observability
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/grafana.yaml
kubectl apply -f k8s/observability/
```

## 5. Exact Test/Verification Commands

### Pod Health
```bash
kubectl get pods -n shopmicro
```

### Connectivity Verification
```bash
# Frontend via LoadBalancer Service
kubectl get svc frontend -n shopmicro

# Health Check via Ingress Rewrite
INGRESS_URL=$(kubectl get ingress shopmicro-ingress -n shopmicro -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -H "Host: shopmicro.local" http://$INGRESS_URL/api/health
```

### Scaling Test
```bash
# Monitor HPA
kubectl get hpa -w -n shopmicro
```

## 6. Observability Usage Guide
- **Grafana Dashboards**: Access via `http://<node-ip>:3000` (NodePort) or Ingress.
  - *Login*: `admin` / `admin`
- **Metrics**: Prometheus scrapes at `/metrics` across all services.
- **Logs**: Loki aggregates all container logs. Query via Grafana "Explore" tab (Source: Loki).
- **Traces**: Tempo captures spans. Search for TraceIDs in Grafana (Source: Tempo).

## 7. Rollback Procedure
If a deployment fails, revert to the previous stable version:
```bash
kubectl rollout undo deployment/backend -n shopmicro
kubectl rollout undo deployment/frontend -n shopmicro
kubectl rollout undo deployment/ml-service-deployment -n shopmicro
```

## 8. Security Controls Implemented
- **Namespace Isolation**: All resources reside in the `shopmicro` namespace.
- **Least Privilege**: Postgres uses `PGDATA` subdirectories for volume safety.
- **Volume Security**: `securityContext` with `fsGroup: 10001` configured for Loki/Tempo.
- **Secrets Management**: Sensitive data injected via K8s Secrets.
- **Ingress Controller**: Centralized entry point with path-based routing.

## 9. Backup/Restore Procedure
Refer to the detailed runbooks:
- [Postgres Backup/Restore](./runbooks/POSTGRES_BACKUP_RESTORE.md)
- [Incident Runbook](./runbooks/INCIDENT_RUNBOOK.md)

## 10. Known Limitations and Next Improvements
- **Limitations**: Currently uses standard `gp2` storage; production may require `gp3` or EFS for multi-node writes.
- **Improvements**: 
  - Integration with AWS Secrets Manager for secret rotation.
  - Blue/Green deployment strategy via ArgoCD.
  - Enhanced WAF integration on the Ingress Load Balancer.
