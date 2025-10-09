.PHONY: help install-dev install-stage install-prod \
        docker-build docker-up docker-down docker-logs \
        k8s-deploy-dev k8s-deploy-stage k8s-deploy-prod \
        k8s-status k8s-logs ansible-check lint test clean

# Default target
.DEFAULT_GOAL := help

# Environment variables
ENV ?= dev
DOCKER_TAG ?= latest
DOCKER_IMAGE := ecommerce-backend

##@ Help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Ansible
ansible-check: ## Validate Ansible playbooks syntax
	@echo "Checking Ansible playbooks syntax..."
	@cd ansible && ansible-playbook playbooks/main.yml --syntax-check

install-dev: ## Install infrastructure for development environment
	@echo "Installing infrastructure for development environment..."
	@cd ansible && ansible-playbook -i inventory/dev playbooks/main.yml -e "environment=dev"

install-stage: ## Install infrastructure for staging environment
	@echo "Installing infrastructure for staging environment..."
	@cd ansible && ansible-playbook -i inventory/stage playbooks/main.yml -e "environment=stage"

install-prod: ## Install infrastructure for production environment
	@echo "Installing infrastructure for production environment..."
	@cd ansible && ansible-playbook -i inventory/prod playbooks/main.yml -e "environment=prod"

ansible-ping: ## Test Ansible connectivity to hosts
	@echo "Testing connectivity to $(ENV) hosts..."
	@cd ansible && ansible all -i inventory/$(ENV) -m ping

##@ Docker
docker-build: ## Build Docker image
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) -f docker/Dockerfile .

docker-up: ## Start Docker Compose services
	@echo "Starting Docker Compose services..."
	@cd docker && docker-compose up -d

docker-down: ## Stop Docker Compose services
	@echo "Stopping Docker Compose services..."
	@cd docker && docker-compose down

docker-logs: ## View Docker Compose logs
	@cd docker && docker-compose logs -f

docker-clean: ## Remove Docker containers, images, and volumes
	@echo "Cleaning Docker resources..."
	@cd docker && docker-compose down -v
	@docker system prune -f

##@ Kubernetes
k8s-deploy-dev: ## Deploy to development Kubernetes environment
	@echo "Deploying to development environment..."
	@kubectl apply -f kubernetes/namespace-dev.yml
	@kubectl apply -f kubernetes/configmap-dev.yml
	@kubectl apply -f kubernetes/secrets-dev.yml
	@kubectl apply -f kubernetes/deployment-dev.yml

k8s-deploy-stage: ## Deploy to staging Kubernetes environment
	@echo "Deploying to staging environment..."
	@kubectl apply -f kubernetes/namespace-stage.yml
	@kubectl apply -f kubernetes/configmap-stage.yml
	@kubectl apply -f kubernetes/secrets-stage.yml
	@kubectl apply -f kubernetes/deployment-stage.yml

k8s-deploy-prod: ## Deploy to production Kubernetes environment
	@echo "Deploying to production environment..."
	@kubectl apply -f kubernetes/namespace-prod.yml
	@kubectl apply -f kubernetes/configmap-prod.yml
	@kubectl apply -f kubernetes/secrets-prod.yml
	@kubectl apply -f kubernetes/deployment-prod.yml

k8s-status: ## Check Kubernetes deployment status
	@echo "Checking status for $(ENV) environment..."
	@kubectl get all -n ecommerce-$(ENV)

k8s-logs: ## View Kubernetes pod logs
	@echo "Viewing logs for $(ENV) environment..."
	@kubectl logs -l app=ecommerce-backend -n ecommerce-$(ENV) --tail=100

k8s-rollback: ## Rollback Kubernetes deployment
	@echo "Rolling back deployment in $(ENV) environment..."
	@kubectl rollout undo deployment/ecommerce-backend -n ecommerce-$(ENV)

k8s-delete: ## Delete Kubernetes resources
	@echo "Deleting resources in $(ENV) environment..."
	@kubectl delete -f kubernetes/deployment-$(ENV).yml
	@kubectl delete -f kubernetes/secrets-$(ENV).yml
	@kubectl delete -f kubernetes/configmap-$(ENV).yml
	@kubectl delete -f kubernetes/namespace-$(ENV).yml

##@ Testing
lint: ## Lint all configuration files
	@echo "Linting YAML files..."
	@yamllint -d "{extends: default, rules: {line-length: {max: 120}}}" ansible/ kubernetes/ docker/
	@echo "Linting Ansible playbooks..."
	@ansible-lint ansible/playbooks/

test-ansible: ansible-check ## Test Ansible playbooks
	@echo "Testing Ansible playbooks in check mode..."
	@cd ansible && ansible-playbook -i inventory/dev playbooks/main.yml --check -e "environment=dev"

test-k8s: ## Test Kubernetes manifests
	@echo "Validating Kubernetes manifests..."
	@kubectl apply -f kubernetes/ --dry-run=client

test-docker: ## Test Docker build
	@echo "Testing Docker build..."
	@docker build -t $(DOCKER_IMAGE):test -f docker/Dockerfile .

##@ Utilities
clean: ## Clean temporary files and caches
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.retry" -delete
	@find . -type f -name "*.log" -delete
	@rm -rf /tmp/ansible_facts/
	@rm -f /tmp/ansible.log

setup: ## Initial setup - install dependencies
	@echo "Setting up development environment..."
	@pip install ansible ansible-lint yamllint
	@echo "Setup complete!"

check-deps: ## Check if required tools are installed
	@echo "Checking required dependencies..."
	@command -v ansible >/dev/null 2>&1 || { echo "Ansible is not installed"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "Docker is not installed"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is not installed"; exit 1; }
	@echo "All dependencies are installed!"

##@ Documentation
docs-serve: ## Serve documentation locally
	@echo "Serving documentation..."
	@python3 -m http.server 8000

##@ CI/CD
ci-test: lint test-ansible test-k8s test-docker ## Run all CI tests
	@echo "All CI tests passed!"

.PHONY: all
all: check-deps ci-test ## Run all checks and tests
