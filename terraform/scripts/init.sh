#!/bin/bash
# Script para inicializar Terraform

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar argumentos
if [ $# -lt 2 ]; then
    log_error "Uso: $0 <provider> <environment>"
    log_info "Ejemplo: $0 doks dev"
    log_info "Ejemplo: $0 gke prod"
    exit 1
fi

PROVIDER=$1
ENVIRONMENT=$2

# Validar provider
if [[ "$PROVIDER" != "doks" && "$PROVIDER" != "gke" ]]; then
    log_error "Provider debe ser 'doks' o 'gke'"
    exit 1
fi

# Validar environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Environment debe ser 'dev' o 'prod'"
    exit 1
fi

# Directorio de trabajo
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/environments/${ENVIRONMENT}/${PROVIDER}"

if [ ! -d "$WORK_DIR" ]; then
    log_error "Directorio no encontrado: $WORK_DIR"
    exit 1
fi

cd "$WORK_DIR"
log_info "Directorio de trabajo: $WORK_DIR"

# Verificar que existe terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    log_warning "terraform.tfvars no encontrado"
    if [ -f "terraform.tfvars.example" ]; then
        log_info "Copiando terraform.tfvars.example a terraform.tfvars"
        cp terraform.tfvars.example terraform.tfvars
        log_warning "Por favor, edita terraform.tfvars con tus valores antes de continuar"
        exit 1
    else
        log_error "No se encontró terraform.tfvars.example"
        exit 1
    fi
fi

# Inicializar Terraform
log_info "Inicializando Terraform..."
terraform init -upgrade

log_info "Validando configuración..."
terraform validate

log_info "Formateando archivos..."
terraform fmt -recursive

log_info "✅ Inicialización completada exitosamente"
log_info ""
log_info "Próximos pasos:"
log_info "  1. Revisar el plan: terraform plan"
log_info "  2. Aplicar cambios: terraform apply"
log_info "  o usar: ./scripts/plan.sh $PROVIDER $ENVIRONMENT"
