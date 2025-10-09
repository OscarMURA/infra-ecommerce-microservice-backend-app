# Jenkins Configuration for Ecommerce Microservice Backend

This directory contains Jenkins configuration files and helper scripts.

## Prerequisites

1. Jenkins server installed and running
2. Required Jenkins plugins:
   - Pipeline
   - Docker Pipeline
   - Kubernetes
   - SonarQube Scanner
   - Git
   - Credentials Binding

## Setup Instructions

### 1. Configure Jenkins Credentials

Add the following credentials in Jenkins (Manage Jenkins > Credentials):

- `docker-registry-url`: String credential for Docker registry URL
- `docker-registry-credentials`: Username with password for Docker registry
- `sonarqube-url`: String credential for SonarQube server URL (e.g., http://sonarqube-vm:9000)
- `sonarqube-token`: Secret text for SonarQube authentication token
- `kubeconfig-file`: Secret file for Kubernetes configuration

### 2. Configure SonarQube Integration

1. Access SonarQube server (external VM)
2. Create a new project for the ecommerce microservice
3. Generate an authentication token
4. Add token to Jenkins credentials as `sonarqube-token`

### 3. Create Jenkins Pipeline Job

1. Create a new Pipeline job in Jenkins
2. Configure SCM to point to this repository
3. Set the pipeline script path to `Jenkinsfile`
4. Enable build parameters

## SonarQube External VM Setup

SonarQube runs as a separate service on an external VM. Configuration:

- Access URL: http://sonarqube-vm:9000
- Default credentials: admin/admin (change after first login)
- Project key: ecommerce-microservice

### SonarQube Quality Gates

The pipeline includes a quality gate check that will fail the build if:
- Code coverage is below threshold
- Critical or blocker issues are found
- Code duplications exceed limits
- Security vulnerabilities are detected

## Pipeline Parameters

- **ENVIRONMENT**: Select target environment (dev/stage/prod)
- **ACTION**: Choose action to perform:
  - `deploy`: Build and deploy application
  - `rollback`: Rollback to previous version
  - `setup-infrastructure`: Run Ansible playbooks to setup infrastructure

## Usage Examples

### Deploy to Development
```
Environment: dev
Action: deploy
```

### Setup Infrastructure for Staging
```
Environment: stage
Action: setup-infrastructure
```

### Rollback Production Deployment
```
Environment: prod
Action: rollback
```
