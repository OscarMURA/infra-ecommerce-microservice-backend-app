#!/bin/bash
# Script de validación del cluster de Kubernetes

set -e

PROVIDER=$1
ENVIRONMENT=$2

echo "🔍 Validando cluster ${PROVIDER} ${ENVIRONMENT}..."

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${YELLOW}➜${NC} $1"
}

# Leer outputs de Terraform
if [ ! -f "outputs.json" ]; then
    log_error "outputs.json no encontrado"
    exit 1
fi

CLUSTER_NAME=$(jq -r '.cluster_name.value' outputs.json)
log_info "Cluster: $CLUSTER_NAME"

# Configurar kubectl según el provider
if [ "$PROVIDER" == "doks" ]; then
    log_info "Configurando kubectl para DOKS..."
    
    # Autenticar doctl si tenemos el token
    if [ -n "$DIGITALOCEAN_TOKEN" ]; then
        doctl auth init --access-token "$DIGITALOCEAN_TOKEN" >/dev/null 2>&1
    fi
    
    doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" || {
        log_error "No se pudo configurar kubectl para DOKS"
        log_info "Verificar que doctl esté instalado y autenticado"
        exit 1
    }
elif [ "$PROVIDER" == "gke" ]; then
    log_info "Configurando kubectl para GKE..."
    
    # Autenticar gcloud si tenemos las credenciales
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" >/dev/null 2>&1
    fi
    
    # Obtener información del cluster
    PROJECT_ID=$(jq -r '.project_id.value // .cluster_id.value' outputs.json | cut -d'/' -f4)
    REGION=$(jq -r '.cluster_region.value // .region.value' outputs.json)
    
    # Configurar kubectl para GKE
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region "$REGION" \
        --project "$PROJECT_ID" || {
        log_error "No se pudo configurar kubectl para GKE"
        log_info "Verificar que gcloud esté instalado y autenticado"
        exit 1
    }
else
    log_error "Provider no soportado: $PROVIDER"
    log_info "Providers soportados: doks, gke"
    exit 1
fi

log_success "kubectl configurado"

# Verificar conectividad con reintentos
log_info "Verificando conectividad con el cluster..."
MAX_RETRIES=5
RETRY_COUNT=0
CONNECTED=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if kubectl cluster-info 2>/dev/null | head -1; then
        CONNECTED=true
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        log_info "Intento $RETRY_COUNT de $MAX_RETRIES falló. Reintentando en 5 segundos..."
        sleep 5
    fi
done

if [ "$CONNECTED" = true ]; then
    log_success "Conectividad OK"
else
    log_error "No se pudo conectar al cluster después de $MAX_RETRIES intentos"
    log_info "Verificando configuración de kubectl..."
    kubectl config view
    log_info "Contexto actual:"
    kubectl config current-context
    exit 1
fi

# Verificar nodos
log_info "Verificando nodos..."
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODE_COUNT" -gt 0 ]; then
    log_success "Nodos encontrados: $NODE_COUNT"
    kubectl get nodes
else
    log_error "No se encontraron nodos"
    exit 1
fi

# Verificar que los nodos estén Ready
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | wc -l)
if [ "$NOT_READY" -gt 0 ]; then
    log_error "$NOT_READY nodos no están Ready"
    kubectl get nodes
    exit 1
else
    log_success "Todos los nodos están Ready"
fi

# Verificar componentes del sistema
log_info "Verificando componentes del sistema..."
kubectl get pods -n kube-system

# Verificar namespaces
log_info "Verificando namespaces..."
kubectl get namespaces

# Resumen
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Validación completada exitosamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cluster: $CLUSTER_NAME"
echo "Provider: $PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "Nodos: $NODE_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
