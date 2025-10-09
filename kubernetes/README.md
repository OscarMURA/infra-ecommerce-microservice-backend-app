# Kubernetes Manifests Documentation

This directory contains Kubernetes manifests for deploying the ecommerce microservice backend application across different environments.

## Directory Structure

```
kubernetes/
├── namespace-{env}.yml      # Namespace definitions
├── configmap-{env}.yml      # Configuration data
├── secrets-{env}.yml        # Sensitive data
└── deployment-{env}.yml     # Deployments, Services, Ingress
```

## Environments

- **dev**: Development environment
- **stage**: Staging environment  
- **prod**: Production environment

## Resource Files

### Namespaces (namespace-*.yml)

Creates isolated namespaces for each environment.

**Features:**
- Environment isolation
- Resource quotas (can be added)
- Access control separation

**Apply:**
```bash
kubectl apply -f kubernetes/namespace-dev.yml
```

### ConfigMaps (configmap-*.yml)

Non-sensitive configuration data for the application.

**Contains:**
- Environment name
- Log level
- Database connection details (non-sensitive)
- Redis connection details
- Application port

**Apply:**
```bash
kubectl apply -f kubernetes/configmap-dev.yml
```

**View:**
```bash
kubectl get configmap -n ecommerce-dev
kubectl describe configmap ecommerce-config -n ecommerce-dev
```

### Secrets (secrets-*.yml)

Sensitive data encoded in base64.

**Contains:**
- Database username and password
- JWT secret keys
- API keys (to be added as needed)

**Security Notes:**
- Values are base64 encoded (NOT encrypted)
- Update with actual secure values before deployment
- Consider using external secret management (Vault, AWS Secrets Manager)
- Never commit actual production secrets

**Create base64 encoded values:**
```bash
echo -n "my-secret-value" | base64
```

**Apply:**
```bash
kubectl apply -f kubernetes/secrets-dev.yml
```

**View (values are hidden by default):**
```bash
kubectl get secret -n ecommerce-dev
kubectl describe secret ecommerce-secrets -n ecommerce-dev
```

**Decode secret (for debugging only):**
```bash
kubectl get secret ecommerce-secrets -n ecommerce-dev -o jsonpath='{.data.db_password}' | base64 -d
```

### Deployments (deployment-*.yml)

Complete application deployment including Deployment, Service, and Ingress.

**Components:**

#### Deployment
- Manages application pods
- Rolling update strategy
- Resource limits and requests
- Health checks (liveness and readiness probes)
- Environment variables from ConfigMaps and Secrets

**Replica Configuration:**
- Dev: 2 replicas
- Stage: 3 replicas
- Prod: 5 replicas

**Resource Allocation:**
- Dev: 250m CPU / 256Mi RAM (request), 500m CPU / 512Mi RAM (limit)
- Stage: 500m CPU / 512Mi RAM (request), 1000m CPU / 1Gi RAM (limit)
- Prod: 1000m CPU / 1Gi RAM (request), 2000m CPU / 2Gi RAM (limit)

#### Service
- ClusterIP type (internal access)
- Exposes port 80 internally
- Routes to container port 3000

#### Ingress
- HTTP/HTTPS routing
- Host-based routing
- TLS configuration (prod only)
- Nginx ingress controller annotations

**Apply:**
```bash
kubectl apply -f kubernetes/deployment-dev.yml
```

## Deployment Workflow

### Initial Deployment

```bash
# 1. Create namespace
kubectl apply -f kubernetes/namespace-dev.yml

# 2. Apply configuration
kubectl apply -f kubernetes/configmap-dev.yml

# 3. Apply secrets
kubectl apply -f kubernetes/secrets-dev.yml

# 4. Deploy application
kubectl apply -f kubernetes/deployment-dev.yml
```

### Update Deployment

```bash
# Update image version
kubectl set image deployment/ecommerce-backend \
  ecommerce-backend=registry.dev.ecommerce.local/ecommerce-backend:v1.2.0 \
  -n ecommerce-dev

# Or apply updated manifest
kubectl apply -f kubernetes/deployment-dev.yml
```

### Monitor Deployment

```bash
# Watch rollout status
kubectl rollout status deployment/ecommerce-backend -n ecommerce-dev

# Check pod status
kubectl get pods -n ecommerce-dev -w

# View deployment history
kubectl rollout history deployment/ecommerce-backend -n ecommerce-dev
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/ecommerce-backend -n ecommerce-dev

# Rollback to specific revision
kubectl rollout undo deployment/ecommerce-backend --to-revision=2 -n ecommerce-dev
```

## Operations

### Scaling

```bash
# Scale manually
kubectl scale deployment/ecommerce-backend --replicas=10 -n ecommerce-dev

# Auto-scaling (requires HPA configuration)
kubectl autoscale deployment/ecommerce-backend \
  --min=2 --max=10 --cpu-percent=80 \
  -n ecommerce-dev
```

### Logs

```bash
# View logs from all pods
kubectl logs -l app=ecommerce-backend -n ecommerce-dev

# Follow logs
kubectl logs -f deployment/ecommerce-backend -n ecommerce-dev

# View logs from specific pod
kubectl logs <pod-name> -n ecommerce-dev

# Previous container logs (if crashed)
kubectl logs <pod-name> -n ecommerce-dev --previous
```

### Debugging

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce-dev

# Execute commands in pod
kubectl exec -it <pod-name> -n ecommerce-dev -- /bin/sh

# Port forward for local testing
kubectl port-forward deployment/ecommerce-backend 3000:3000 -n ecommerce-dev
```

### Resource Usage

```bash
# Check resource usage
kubectl top pods -n ecommerce-dev
kubectl top nodes

# Check resource quotas
kubectl describe resourcequota -n ecommerce-dev
```

## Health Checks

### Liveness Probe
- Checks if container is alive
- Restarts container if fails
- Endpoint: `/health`
- Initial delay: 30 seconds
- Period: 10 seconds

### Readiness Probe
- Checks if container is ready to serve traffic
- Removes from service if fails
- Endpoint: `/health`
- Initial delay: 10 seconds
- Period: 5 seconds

## Ingress Configuration

### Development
- Host: `dev.ecommerce.local`
- HTTP only
- Local DNS or hosts file required

### Staging
- Host: `stage.ecommerce.local`
- HTTP only
- Internal network access

### Production
- Host: `ecommerce.com`
- HTTPS with TLS certificate
- Let's Encrypt certificate automation
- Public internet access

### Testing Ingress

```bash
# Add to /etc/hosts for local testing
echo "192.168.1.10 dev.ecommerce.local" | sudo tee -a /etc/hosts

# Test connectivity
curl http://dev.ecommerce.local/health
```

## Security Best Practices

### 1. Secrets Management
```bash
# Use external secret stores
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
# - Google Secret Manager
```

### 2. Network Policies
```bash
# Restrict pod-to-pod communication
# Create network policies as needed
```

### 3. RBAC
```bash
# Implement Role-Based Access Control
# Limit permissions per namespace
```

### 4. Pod Security
```bash
# Use security contexts
# Run as non-root user (already configured)
# Read-only root filesystem (consider adding)
```

### 5. Image Security
```bash
# Scan images for vulnerabilities
# Use private registries
# Sign images
# Use specific tags (not :latest in prod)
```

## Backup and Disaster Recovery

### Backup ConfigMaps and Secrets
```bash
kubectl get configmap ecommerce-config -n ecommerce-dev -o yaml > configmap-backup.yml
kubectl get secret ecommerce-secrets -n ecommerce-dev -o yaml > secrets-backup.yml
```

### Backup Deployments
```bash
kubectl get deployment ecommerce-backend -n ecommerce-dev -o yaml > deployment-backup.yml
```

### Restore
```bash
kubectl apply -f configmap-backup.yml
kubectl apply -f secrets-backup.yml
kubectl apply -f deployment-backup.yml
```

## Troubleshooting

### Pod Not Starting
```bash
# Check events
kubectl describe pod <pod-name> -n ecommerce-dev

# Common issues:
# - Image pull errors (check registry access)
# - Resource limits (check node capacity)
# - ConfigMap/Secret not found
# - Startup probe failures
```

### CrashLoopBackOff
```bash
# Check logs
kubectl logs <pod-name> -n ecommerce-dev --previous

# Common causes:
# - Application errors
# - Missing environment variables
# - Failed health checks
# - Resource constraints
```

### Service Not Accessible
```bash
# Check service
kubectl get svc -n ecommerce-dev
kubectl describe svc ecommerce-backend -n ecommerce-dev

# Check endpoints
kubectl get endpoints -n ecommerce-dev

# Common issues:
# - Selector mismatch
# - No ready pods
# - Network policies blocking traffic
```

### Ingress Not Working
```bash
# Check ingress
kubectl get ingress -n ecommerce-dev
kubectl describe ingress ecommerce-backend -n ecommerce-dev

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Common issues:
# - Ingress controller not installed
# - DNS not configured
# - SSL/TLS certificate issues
```

## Monitoring and Observability

### Prometheus Integration
```yaml
# Add to deployment annotations
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "3000"
  prometheus.io/path: "/metrics"
```

### Grafana Dashboards
- Pod CPU and Memory usage
- Request latency
- Error rates
- Replica count

## Future Enhancements

- [ ] Implement Horizontal Pod Autoscaler (HPA)
- [ ] Add Network Policies
- [ ] Implement Pod Disruption Budgets
- [ ] Add Resource Quotas per namespace
- [ ] Implement Service Mesh (Istio/Linkerd)
- [ ] Add Database StatefulSets
- [ ] Implement GitOps with ArgoCD/Flux

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
