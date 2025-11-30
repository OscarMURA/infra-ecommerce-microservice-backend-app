#!/bin/bash
# =============================================================================
# deploy-alerting.sh - Despliegue de AlertManager y Reglas de Alertas
# E-Commerce Microservices Monitoring Stack
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=============================================="
echo "  Monitoring Stack - AlertManager & Rules"
echo "=============================================="
echo ""

# 1. Verificar conexión a cluster
log_info "Verificando conexión al cluster..."
if ! kubectl cluster-info &>/dev/null; then
    log_error "No se puede conectar al cluster de Kubernetes"
    exit 1
fi
log_success "Conectado al cluster"

# 2. Verificar namespace monitoring existe
log_info "Verificando namespace $NAMESPACE..."
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    log_warn "Namespace $NAMESPACE no existe, creándolo..."
    kubectl create namespace $NAMESPACE
fi
log_success "Namespace $NAMESPACE listo"

# 3. Desplegar AlertManager
log_info "Desplegando AlertManager..."
kubectl apply -f "$SCRIPT_DIR/alertmanager/configmap.yaml"
kubectl apply -f "$SCRIPT_DIR/alertmanager/deployment.yaml"
log_success "AlertManager desplegado"

# 4. Desplegar Reglas de Alertas
log_info "Desplegando reglas de alertas..."
kubectl apply -f "$SCRIPT_DIR/prometheus-rules/alerting-rules.yaml"
log_success "Reglas de alertas desplegadas"

# 5. Actualizar Prometheus para usar AlertManager y las reglas
log_info "Configurando Prometheus para usar AlertManager..."

# Obtener el ConfigMap actual de Prometheus
PROMETHEUS_CM=$(kubectl get configmap prometheus-server -n $NAMESPACE -o yaml 2>/dev/null || echo "")

if [ -n "$PROMETHEUS_CM" ]; then
    # Crear patch para agregar alertmanager config
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alertmanager-rules
  namespace: $NAMESPACE
data:
  alertmanager-config.yml: |
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093
    
    rule_files:
      - /etc/prometheus/alerting-rules.yml
EOF
    log_success "ConfigMap de reglas creado"
else
    log_warn "No se encontró ConfigMap de Prometheus. Puede que necesites configurarlo manualmente."
fi

# 6. Copiar reglas al ConfigMap de Prometheus
log_info "Actualizando ConfigMap de Prometheus con reglas..."
RULES_CONTENT=$(cat "$SCRIPT_DIR/prometheus-rules/alerting-rules.yaml" | grep -A 1000 "alerting-rules.yml:" | tail -n +2 | sed 's/^    //')

kubectl get configmap prometheus-server -n $NAMESPACE -o yaml | \
    sed '/^data:/a\  alerting-rules.yml: |\n'"$(echo "$RULES_CONTENT" | sed 's/^/    /')" | \
    kubectl apply -f - 2>/dev/null || log_warn "No se pudo actualizar ConfigMap automáticamente"

# 7. Reiniciar Prometheus para cargar nuevas configuraciones
log_info "Reiniciando Prometheus para cargar configuración..."
kubectl rollout restart deployment/prometheus-server -n $NAMESPACE 2>/dev/null || \
    log_warn "No se pudo reiniciar Prometheus automáticamente"

# 8. Esperar a que los pods estén listos
log_info "Esperando a que AlertManager esté listo..."
kubectl wait --for=condition=ready pod -l app=alertmanager -n $NAMESPACE --timeout=120s 2>/dev/null || \
    log_warn "Timeout esperando AlertManager. Verificar manualmente."

# 9. Obtener URLs de acceso
echo ""
echo "=============================================="
echo "  DESPLIEGUE COMPLETADO"
echo "=============================================="
echo ""

ALERTMANAGER_IP=$(kubectl get svc alertmanager -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
GRAFANA_IP=$(kubectl get svc grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
PROMETHEUS_IP=$(kubectl get svc prometheus-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

echo "URLs de acceso:"
echo "  - AlertManager: http://$ALERTMANAGER_IP:9093"
echo "  - Prometheus:   http://$PROMETHEUS_IP:9090"
echo "  - Grafana:      http://$GRAFANA_IP"
echo ""
echo "Siguiente paso:"
echo "  1. Importar dashboard de Grafana:"
echo "     - Abrir Grafana → Dashboards → Import"
echo "     - Subir: grafana-dashboards/ecommerce-business.json"
echo ""
echo "  2. Verificar alertas en Prometheus:"
echo "     - http://$PROMETHEUS_IP:9090/alerts"
echo ""
echo "  3. Verificar AlertManager:"
echo "     - http://$ALERTMANAGER_IP:9093"
echo ""
log_success "¡Stack de alertas desplegado exitosamente!"
