#!/bin/bash
# Script para destruir infraestructura

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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

# Advertencia
log_warning "⚠️  ADVERTENCIA: Vas a DESTRUIR toda la infraestructura de $PROVIDER $ENVIRONMENT"
log_warning "Esta acción NO se puede deshacer"
echo ""

# Doble confirmación para producción
if [ "$ENVIRONMENT" == "prod" ]; then
    log_error "🚨 DESTRUCCIÓN DE PRODUCCIÓN 🚨"
    read -p "Escribe 'DELETE PRODUCTION' para continuar: " confirm1
    if [ "$confirm1" != "DELETE PRODUCTION" ]; then
        log_info "Operación cancelada"
        exit 0
    fi
    read -p "¿Estás absolutamente seguro? (escriba 'yes'): " confirm2
    if [ "$confirm2" != "yes" ]; then
        log_info "Operación cancelada"
        exit 0
    fi
else
    read -p "Escribe 'yes' para continuar: " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Operación cancelada"
        exit 0
    fi
fi

# Destruir
log_warning "Destruyendo infraestructura..."
terraform destroy -auto-approve

log_info "✅ Infraestructura destruida"
