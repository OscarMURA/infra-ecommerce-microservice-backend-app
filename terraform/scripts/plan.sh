#!/bin/bash
# Script para ejecutar terraform plan

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar argumentos
if [ $# -lt 2 ]; then
    log_error "Uso: $0 <provider> <environment>"
    log_info "Ejemplo: $0 doks dev"
    exit 1
fi

PROVIDER=$1
ENVIRONMENT=$2

# Directorio de trabajo
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/environments/${ENVIRONMENT}/${PROVIDER}"

if [ ! -d "$WORK_DIR" ]; then
    log_error "Directorio no encontrado: $WORK_DIR"
    exit 1
fi

cd "$WORK_DIR"
log_info "Directorio de trabajo: $WORK_DIR"

# Archivo para guardar el plan
PLAN_FILE="tfplan-${ENVIRONMENT}-${PROVIDER}-$(date +%Y%m%d-%H%M%S)"

log_info "Ejecutando terraform plan..."
terraform plan -out="${PLAN_FILE}"

log_info "✅ Plan generado exitosamente: ${PLAN_FILE}"
log_info ""
log_info "Para aplicar este plan:"
log_info "  cd $WORK_DIR"
log_info "  terraform apply ${PLAN_FILE}"
log_info ""
log_info "o usar: ./scripts/apply.sh $PROVIDER $ENVIRONMENT ${PLAN_FILE}"
