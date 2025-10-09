# Infrastructure for Ecommerce Microservice Backend App

Infrastructure setup for the ecommerce-microservice-backend-app project (Taller 2). This repository contains Ansible playbooks, Jenkins automation, and Kubernetes configurations to prepare and deploy Docker containers across development, staging, and production environments.

## Overview

This infrastructure project provides:

- **Ansible Playbooks**: Automated infrastructure provisioning for Docker and Kubernetes
- **Jenkins CI/CD**: Continuous integration and deployment pipeline with SonarQube integration
- **Docker Configuration**: Multi-stage Dockerfiles and Docker Compose for local development
- **Kubernetes Manifests**: Environment-specific deployments for dev, stage, and prod
- **SonarQube Integration**: Code quality analysis running on an external VM service

## Architecture

```
┌─────────────────┐
│   Jenkins       │
│   (CI/CD)       │◄─── Push triggers build
└────────┬────────┘
         │
         ├─► SonarQube (External VM) ─► Quality Gate
         │
         ├─► Docker Build & Push
         │
         └─► Kubernetes Deploy
                 │
                 ├─► Dev Environment
                 ├─► Stage Environment
                 └─► Prod Environment
```

## Directory Structure

```
.
├── ansible/
│   ├── inventory/          # Environment-specific inventory files
│   │   ├── dev
│   │   ├── stage
│   │   └── prod
│   ├── group_vars/         # Environment variables
│   │   ├── dev.yml
│   │   ├── stage.yml
│   │   └── prod.yml
│   ├── playbooks/          # Ansible playbooks
│   │   ├── main.yml
│   │   ├── install-docker.yml
│   │   └── setup-kubernetes.yml
│   └── templates/          # Configuration templates
│       └── app-config.j2
├── docker/
│   ├── Dockerfile          # Multi-stage production Dockerfile
│   ├── docker-compose.yml  # Local development setup
│   └── nginx.conf          # Nginx reverse proxy configuration
├── jenkins/
│   └── README.md           # Jenkins setup documentation
├── kubernetes/
│   ├── namespace-*.yml     # Namespace definitions
│   ├── configmap-*.yml     # Environment configurations
│   ├── secrets-*.yml       # Sensitive data (base64 encoded)
│   └── deployment-*.yml    # Deployment manifests
├── Jenkinsfile             # Jenkins pipeline definition
└── sonar-project.properties # SonarQube configuration

```

## Prerequisites

- **Ansible**: Version 2.9 or higher
- **Jenkins**: Version 2.300 or higher with required plugins
- **Docker**: Version 24.0 or higher
- **Kubernetes**: Version 1.28 or higher
- **SonarQube**: External VM running SonarQube 9.x or higher
- **Git**: For version control

## Quick Start

### 1. Configure Inventory Files

Update the inventory files in `ansible/inventory/` with your server IP addresses and SSH keys:

```bash
# Example: ansible/inventory/dev
[dev_servers]
dev-server-1 ansible_host=YOUR_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your_key
```

### 2. Setup Infrastructure with Ansible

```bash
# Install Docker on all servers
cd ansible
ansible-playbook -i inventory/dev playbooks/install-docker.yml

# Setup Kubernetes cluster
ansible-playbook -i inventory/dev playbooks/setup-kubernetes.yml

# Run complete setup
ansible-playbook -i inventory/dev playbooks/main.yml -e "environment=dev"
```

### 3. Configure Jenkins

1. Install required Jenkins plugins:
   - Pipeline
   - Docker Pipeline
   - Kubernetes
   - SonarQube Scanner
   - Git
   - Credentials Binding

2. Add credentials in Jenkins:
   - `docker-registry-url`: Docker registry URL
   - `docker-registry-credentials`: Docker credentials
   - `sonarqube-url`: SonarQube server URL
   - `sonarqube-token`: SonarQube authentication token
   - `kubeconfig-file`: Kubernetes configuration file

3. Create a Pipeline job pointing to the `Jenkinsfile`

### 4. Setup SonarQube (External VM)

SonarQube runs as a separate service on an external VM:

```bash
# On SonarQube VM
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest

# Access at http://sonarqube-vm:9000
# Default credentials: admin/admin (change after first login)
```

Create a project with key `ecommerce-microservice-backend` and generate an authentication token.

### 5. Local Development with Docker Compose

```bash
cd docker
docker-compose up -d

# Access the application at http://localhost:80
# PostgreSQL: localhost:5432
# Redis: localhost:6379
```

## Environment Configuration

### Development (dev)
- **Replicas**: 2
- **Resources**: 250m CPU / 256Mi RAM (request), 500m CPU / 512Mi RAM (limit)
- **Log Level**: DEBUG
- **Domain**: dev.ecommerce.local

### Staging (stage)
- **Replicas**: 3
- **Resources**: 500m CPU / 512Mi RAM (request), 1000m CPU / 1Gi RAM (limit)
- **Log Level**: INFO
- **Domain**: stage.ecommerce.local

### Production (prod)
- **Replicas**: 5
- **Resources**: 1000m CPU / 1Gi RAM (request), 2000m CPU / 2Gi RAM (limit)
- **Log Level**: WARN
- **Domain**: ecommerce.com
- **Features**: TLS/SSL enabled, High Availability, Automated backups

## Jenkins Pipeline Usage

### Deploy to Development
```groovy
Environment: dev
Action: deploy
```

### Setup Infrastructure for Staging
```groovy
Environment: stage
Action: setup-infrastructure
```

### Rollback Production
```groovy
Environment: prod
Action: rollback
```

## Kubernetes Operations

### Deploy to Kubernetes Manually

```bash
# Deploy to dev environment
kubectl apply -f kubernetes/namespace-dev.yml
kubectl apply -f kubernetes/configmap-dev.yml
kubectl apply -f kubernetes/secrets-dev.yml
kubectl apply -f kubernetes/deployment-dev.yml

# Check deployment status
kubectl get pods -n ecommerce-dev
kubectl get services -n ecommerce-dev
kubectl get ingress -n ecommerce-dev
```

### Update Deployment

```bash
# Update image
kubectl set image deployment/ecommerce-backend \
  ecommerce-backend=registry.dev.ecommerce.local/ecommerce-backend:v1.2.0 \
  -n ecommerce-dev

# Check rollout status
kubectl rollout status deployment/ecommerce-backend -n ecommerce-dev
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/ecommerce-backend -n ecommerce-dev

# Rollback to specific revision
kubectl rollout undo deployment/ecommerce-backend --to-revision=2 -n ecommerce-dev
```

## Monitoring and Logging

### View Application Logs

```bash
# View logs from all pods
kubectl logs -l app=ecommerce-backend -n ecommerce-dev

# Follow logs
kubectl logs -f deployment/ecommerce-backend -n ecommerce-dev

# View logs from specific pod
kubectl logs <pod-name> -n ecommerce-dev
```

### Check Application Health

```bash
# Health check endpoint
curl http://dev.ecommerce.local/health

# Check pod status
kubectl get pods -n ecommerce-dev -o wide
```

## Security Considerations

1. **Secrets Management**: 
   - Update Kubernetes secrets with actual secure values
   - Use external secret management tools (e.g., HashiCorp Vault, AWS Secrets Manager)
   - Never commit actual secrets to Git

2. **SSH Keys**:
   - Store SSH private keys securely
   - Use different keys for each environment
   - Implement key rotation policies

3. **Docker Registry**:
   - Use private Docker registries
   - Implement image scanning for vulnerabilities
   - Use image signing for production

4. **Network Security**:
   - Configure network policies in Kubernetes
   - Use TLS/SSL for all external communication
   - Implement firewall rules

## Troubleshooting

### Ansible Connection Issues

```bash
# Test connectivity
ansible all -i ansible/inventory/dev -m ping

# Run with verbose output
ansible-playbook -i ansible/inventory/dev playbooks/main.yml -vvv
```

### Kubernetes Pod Issues

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce-dev

# Check pod logs
kubectl logs <pod-name> -n ecommerce-dev --previous

# Execute commands in pod
kubectl exec -it <pod-name> -n ecommerce-dev -- /bin/sh
```

### Jenkins Build Failures

1. Check Jenkins console output
2. Verify credentials are configured correctly
3. Check SonarQube quality gate status
4. Verify Docker registry connectivity
5. Check Kubernetes cluster accessibility

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in development environment
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Open an issue in the GitHub repository
- Contact the DevOps team
- Check the documentation in each subdirectory

## Changelog

### Version 1.0.0 (Initial Release)
- Complete Ansible automation for infrastructure setup
- Jenkins CI/CD pipeline with SonarQube integration
- Kubernetes manifests for dev, stage, and prod environments
- Docker configuration for containerization
- Environment-specific configurations
- Comprehensive documentation