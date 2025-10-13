#!/bin/bash
# Script para ejecutar terraform apply

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    log_error "Uso: $0 <provider> <environment> [plan_file]"
    log_info "Ejemplo: $0 doks dev"
    log_info "Ejemplo: $0 gke prod tfplan-prod-gke-20250101-120000"
    exit 1
fi

PROVIDER=$1
ENVIRONMENT=$2
PLAN_FILE=${3:-""}

# Directorio de trabajo
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/environments/${ENVIRONMENT}/${PROVIDER}"

if [ ! -d "$WORK_DIR" ]; then
    log_error "Directorio no encontrado: $WORK_DIR"
    exit 1
fi

cd "$WORK_DIR"
log_info "Directorio de trabajo: $WORK_DIR"

# Confirmación para producción
if [ "$ENVIRONMENT" == "prod" ]; then
    log_warning "⚠️  Estás a punto de aplicar cambios en PRODUCCIÓN"
    read -p "¿Estás seguro? (escriba 'yes' para continuar): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Operación cancelada"
        exit 0
    fi
fi

# Aplicar cambios
log_info "Aplicando cambios en $PROVIDER $ENVIRONMENT..."
if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    log_info "Usando plan file: $PLAN_FILE"
    terraform apply "$PLAN_FILE"
else
    terraform apply -auto-approve
fi

log_info "✅ Cambios aplicados exitosamente"
log_info ""
log_info "Obteniendo outputs..."
terraform output

log_info ""
log_info "Para configurar kubectl, ejecuta:"
if [ "$PROVIDER" == "doks" ]; then
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    if [ -n "$CLUSTER_NAME" ]; then
        echo -e "${BLUE}  doctl kubernetes cluster kubeconfig save ${CLUSTER_NAME}${NC}"
    fi
elif [ "$PROVIDER" == "gke" ]; then
    terraform output -raw kubeconfig_command 2>/dev/null || true
fi
