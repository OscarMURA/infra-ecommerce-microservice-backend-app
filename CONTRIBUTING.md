# Contributing to Infrastructure for Ecommerce Microservice Backend

Thank you for your interest in contributing to this infrastructure project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Directory Structure](#directory-structure)

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/infra-ecommerce-microservice-backend-app.git
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/OscarMURA/infra-ecommerce-microservice-backend-app.git
   ```

## Development Setup

### Prerequisites

Install the following tools:

- **Ansible**: `pip install ansible`
- **Docker**: Follow [official installation guide](https://docs.docker.com/engine/install/)
- **kubectl**: Follow [official installation guide](https://kubernetes.io/docs/tasks/tools/)
- **Linting tools**:
  ```bash
  pip install ansible-lint yamllint
  ```

### Local Environment

1. Create a local test environment using Docker Compose:
   ```bash
   cd docker
   docker-compose up -d
   ```

2. Test Ansible playbooks in check mode:
   ```bash
   cd ansible
   ansible-playbook -i inventory/dev playbooks/main.yml --check
   ```

## Making Changes

### Branch Naming Convention

Use descriptive branch names:

- Feature: `feature/add-monitoring`
- Bug fix: `fix/ansible-connection-issue`
- Documentation: `docs/update-readme`
- Infrastructure: `infra/add-new-environment`

### Creating a Branch

```bash
git checkout -b feature/your-feature-name
```

### Commit Message Guidelines

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(ansible): add monitoring role for Prometheus

Added new Ansible role to install and configure Prometheus
on all server nodes.

Closes #123
```

```
fix(kubernetes): correct resource limits in prod deployment

Updated CPU and memory limits to match infrastructure capacity.
```

## Testing

### Ansible Playbooks

1. **Syntax Check:**
   ```bash
   ansible-playbook playbooks/main.yml --syntax-check
   ```

2. **Dry Run:**
   ```bash
   ansible-playbook -i inventory/dev playbooks/main.yml --check
   ```

3. **Linting:**
   ```bash
   ansible-lint playbooks/main.yml
   ```

### Kubernetes Manifests

1. **Validate YAML:**
   ```bash
   yamllint kubernetes/
   ```

2. **Dry Run Apply:**
   ```bash
   kubectl apply -f kubernetes/deployment-dev.yml --dry-run=client
   ```

3. **Validate Resources:**
   ```bash
   kubectl apply -f kubernetes/deployment-dev.yml --dry-run=server
   ```

### Docker

1. **Build Test:**
   ```bash
   docker build -t test-image -f docker/Dockerfile .
   ```

2. **Compose Validation:**
   ```bash
   docker-compose -f docker/docker-compose.yml config
   ```

3. **Security Scan:**
   ```bash
   docker scan test-image
   ```

## Pull Request Process

### Before Submitting

1. **Update from upstream:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes:**
   - Run all relevant tests
   - Verify in local environment
   - Check for syntax errors

3. **Update documentation:**
   - Update README if needed
   - Add/update comments
   - Update relevant documentation files

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   git push origin feature/your-feature-name
   ```

### Submitting Pull Request

1. Go to the repository on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill in the PR template:
   - Description of changes
   - Related issues
   - Testing performed
   - Screenshots (if UI changes)

### PR Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Fixes #(issue number)

## Testing Performed
- [ ] Ansible playbooks tested
- [ ] Kubernetes manifests validated
- [ ] Docker builds successfully
- [ ] Documentation updated

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have tested in a local environment
```

### Review Process

1. **Automated checks** will run on your PR
2. **Maintainers** will review your code
3. **Address feedback** by making additional commits
4. Once approved, maintainers will **merge** your PR

## Coding Standards

### Ansible

1. **YAML Formatting:**
   - Use 2 spaces for indentation
   - Use `---` at the start of files
   - Quote strings when needed

2. **Naming:**
   - Use descriptive task names
   - Use snake_case for variables
   - Use lowercase for file names

3. **Best Practices:**
   - Make playbooks idempotent
   - Use handlers for service restarts
   - Use `when` conditions appropriately
   - Tag tasks for selective execution

**Example:**
```yaml
---
- name: Install and configure Docker
  hosts: all
  become: yes
  tasks:
    - name: Install Docker packages
      apt:
        name: docker-ce
        state: present
      tags:
        - docker
        - install
```

### Kubernetes

1. **YAML Formatting:**
   - Use 2 spaces for indentation
   - Order: apiVersion, kind, metadata, spec

2. **Resource Naming:**
   - Use kebab-case
   - Include environment in name
   - Be descriptive but concise

3. **Best Practices:**
   - Always specify resource limits
   - Use labels consistently
   - Include liveness and readiness probes
   - Use ConfigMaps for configuration

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-backend-dev
  labels:
    app: backend
    environment: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
```

### Docker

1. **Dockerfile:**
   - Use official base images
   - Minimize layers
   - Order commands by change frequency
   - Use multi-stage builds
   - Don't run as root

2. **docker-compose.yml:**
   - Use version 3.8+
   - Define networks explicitly
   - Use named volumes
   - Set restart policies

**Example:**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
RUN adduser -D appuser
COPY --from=builder --chown=appuser:appuser /app .
USER appuser
CMD ["node", "server.js"]
```

### Documentation

1. **Markdown:**
   - Use ATX-style headers (#)
   - Include table of contents for long documents
   - Use code blocks with language specification
   - Include examples

2. **Comments:**
   - Write clear, concise comments
   - Explain "why" not "what"
   - Keep comments up-to-date

## Directory Structure

When adding new files, follow this structure:

```
ansible/
├── playbooks/          # Main playbooks
├── roles/              # Ansible roles
├── inventory/          # Host inventories
├── group_vars/         # Group variables
├── host_vars/          # Host variables
└── templates/          # Jinja2 templates

docker/
├── Dockerfile          # Production Dockerfile
├── docker-compose.yml  # Development compose
└── *.conf             # Configuration files

kubernetes/
├── base/              # Base manifests (optional)
├── overlays/          # Kustomize overlays (optional)
└── *.yml              # Kubernetes resources

jenkins/
├── pipelines/         # Additional pipelines
└── scripts/           # Helper scripts
```

## Questions?

- Open an issue for questions
- Check existing issues for similar questions
- Contact maintainers via email

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.

## Thank You!

Your contributions help make this project better for everyone. Thank you for taking the time to contribute! 🎉
