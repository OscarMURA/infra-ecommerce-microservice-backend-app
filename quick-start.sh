#!/bin/bash

# Quick Start Script for Ecommerce Microservice Infrastructure
# This script helps you get started with the infrastructure setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}======================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

# Main script
print_header "Ecommerce Microservice Infrastructure Setup"

echo ""
print_info "Checking prerequisites..."
echo ""

# Check prerequisites
MISSING_DEPS=0

if ! check_command "ansible"; then
    MISSING_DEPS=$((MISSING_DEPS + 1))
    print_info "Install with: pip install ansible"
fi

if ! check_command "docker"; then
    MISSING_DEPS=$((MISSING_DEPS + 1))
    print_info "Install from: https://docs.docker.com/engine/install/"
fi

if ! check_command "kubectl"; then
    MISSING_DEPS=$((MISSING_DEPS + 1))
    print_info "Install from: https://kubernetes.io/docs/tasks/tools/"
fi

if ! check_command "git"; then
    MISSING_DEPS=$((MISSING_DEPS + 1))
    print_info "Install git"
fi

echo ""

if [ $MISSING_DEPS -gt 0 ]; then
    print_error "$MISSING_DEPS required dependencies are missing"
    echo ""
    print_info "Please install missing dependencies and run this script again"
    exit 1
fi

print_success "All prerequisites are installed!"
echo ""

# Show menu
print_header "What would you like to do?"
echo ""
echo "1) Setup local development environment (Docker Compose)"
echo "2) Setup infrastructure for dev environment (Ansible)"
echo "3) Deploy to Kubernetes (dev)"
echo "4) Validate configurations"
echo "5) View documentation"
echo "6) Exit"
echo ""

read -p "Enter your choice [1-6]: " choice

case $choice in
    1)
        print_header "Setting up local development environment"
        print_info "Creating .env file from template..."
        if [ ! -f .env ]; then
            cp .env.example .env
            print_success ".env file created. Please edit it with your values."
        else
            print_info ".env file already exists"
        fi
        
        print_info "Starting Docker Compose services..."
        cd docker
        docker-compose up -d
        print_success "Services started!"
        echo ""
        print_info "Access the application at: http://localhost"
        print_info "PostgreSQL: localhost:5432"
        print_info "Redis: localhost:6379"
        echo ""
        print_info "View logs with: docker-compose logs -f"
        ;;
    
    2)
        print_header "Setting up infrastructure for dev environment"
        print_info "This will run Ansible playbooks to setup Docker and Kubernetes"
        echo ""
        print_info "Before proceeding, please ensure:"
        echo "  1. You have updated ansible/inventory/dev with your server IPs"
        echo "  2. You have SSH access to the servers"
        echo "  3. You have sudo privileges on the servers"
        echo ""
        read -p "Continue? (y/n): " confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            print_info "Running Ansible playbooks..."
            cd ansible
            ansible-playbook -i inventory/dev playbooks/main.yml -e "environment=dev"
            print_success "Infrastructure setup complete!"
        else
            print_info "Cancelled"
        fi
        ;;
    
    3)
        print_header "Deploying to Kubernetes (dev)"
        print_info "This will deploy the application to your Kubernetes cluster"
        echo ""
        print_info "Checking Kubernetes connectivity..."
        if kubectl cluster-info &> /dev/null; then
            print_success "Connected to Kubernetes cluster"
            echo ""
            print_info "Deploying resources..."
            kubectl apply -f kubernetes/namespace-dev.yml
            kubectl apply -f kubernetes/configmap-dev.yml
            kubectl apply -f kubernetes/secrets-dev.yml
            kubectl apply -f kubernetes/deployment-dev.yml
            print_success "Deployment complete!"
            echo ""
            print_info "Check status with: kubectl get all -n ecommerce-dev"
        else
            print_error "Cannot connect to Kubernetes cluster"
            print_info "Please configure kubectl and try again"
        fi
        ;;
    
    4)
        print_header "Validating configurations"
        print_info "Checking Ansible playbooks syntax..."
        cd ansible
        ansible-playbook playbooks/main.yml --syntax-check
        print_success "Ansible playbooks are valid"
        echo ""
        
        print_info "Validating Kubernetes manifests..."
        cd ../kubernetes
        for file in *.yml; do
            if kubectl apply -f "$file" --dry-run=client &> /dev/null; then
                print_success "$file is valid"
            else
                print_error "$file has errors"
            fi
        done
        echo ""
        
        print_info "Validating Docker configuration..."
        cd ../docker
        docker-compose config > /dev/null
        print_success "Docker Compose configuration is valid"
        ;;
    
    5)
        print_header "Documentation"
        echo ""
        echo "Main documentation:"
        echo "  - README.md                 - Main project documentation"
        echo "  - CONTRIBUTING.md           - Contributing guidelines"
        echo "  - CHANGELOG.md              - Project changelog"
        echo ""
        echo "Component-specific documentation:"
        echo "  - ansible/README.md         - Ansible playbooks guide"
        echo "  - docker/README.md          - Docker setup guide"
        echo "  - kubernetes/README.md      - Kubernetes deployment guide"
        echo "  - jenkins/README.md         - Jenkins CI/CD guide"
        echo ""
        echo "Configuration files:"
        echo "  - .env.example              - Environment variables template"
        echo "  - sonar-project.properties  - SonarQube configuration"
        echo "  - Makefile                  - Common commands"
        echo ""
        read -p "Press Enter to continue..."
        ;;
    
    6)
        print_info "Goodbye!"
        exit 0
        ;;
    
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_header "Setup Complete!"
echo ""
print_info "For more information, check the README.md file"
print_info "Use 'make help' to see available commands"
echo ""
