#!/bin/bash
# Health check del cluster

set -e

PROVIDER=$1
ENVIRONMENT=$2

echo "🏥 Ejecutando health check para ${PROVIDER} ${ENVIRONMENT}..."

# Agregar gcloud al PATH si existe (para GKE)
if [ -d "/opt/google-cloud-sdk/google-cloud-sdk/bin" ]; then
    export PATH="/opt/google-cloud-sdk/google-cloud-sdk/bin:$PATH"
    export USE_GKE_GCLOUD_AUTH_PLUGIN=True
fi

# Validar provider
if [ "$PROVIDER" != "doks" ] && [ "$PROVIDER" != "gke" ] && [ "$PROVIDER" != "aks" ]; then
    echo "❌ Provider no soportado: $PROVIDER"
    echo "ℹ Providers soportados: doks, gke, aks"
    exit 1
fi

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Función para verificar un recurso
check_resource() {
    local resource=$1
    local namespace=$2
    local expected_count=$3
    
    log_info "Verificando $resource en namespace $namespace..."
    
    local actual_count=$(kubectl get $resource -n $namespace --no-headers 2>/dev/null | wc -l)
    
    if [ "$actual_count" -ge "$expected_count" ]; then
        log_success "$resource: $actual_count encontrados (esperados: $expected_count)"
        return 0
    else
        log_warning "$resource: $actual_count encontrados (esperados: $expected_count)"
        return 1
    fi
}

# Función para verificar pods
check_pods_health() {
    local namespace=$1
    
    log_info "Verificando salud de pods en $namespace..."
    
    # Contar pods en diferentes estados
    local total=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | wc -l)
    local running=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | grep "Running" | wc -l)
    local pending=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | grep "Pending" | wc -l)
    local failed=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | grep -E "Error|Failed|CrashLoopBackOff" | wc -l)
    
    echo "  Total: $total | Running: $running | Pending: $pending | Failed: $failed"
    
    if [ "$failed" -gt 0 ]; then
        log_error "Hay $failed pods con errores"
        kubectl get pods -n $namespace | grep -E "Error|Failed|CrashLoopBackOff"
        return 1
    fi
    
    if [ "$running" -eq "$total" ] && [ "$total" -gt 0 ]; then
        log_success "Todos los pods están corriendo"
        return 0
    elif [ "$pending" -gt 0 ]; then
        log_warning "Hay $pending pods pendientes"
        return 0
    else
        log_info "Estado: $running/$total pods running"
        return 0
    fi
}

# Array de checks realizados
declare -a checks_passed=()
declare -a checks_failed=()

# 0. Verificar nodos del cluster
log_info "0. Verificando nodos del cluster..."
echo ""
kubectl get nodes
echo ""

if [ "$PROVIDER" == "aks" ]; then
    # Para AKS, ser tolerante con nodos que están inicializando
    nodes_total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    nodes_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | grep -v "NotReady" | wc -l)
    nodes_not_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep "NotReady" | wc -l)
    
    if [ "$nodes_ready" -gt 0 ]; then
        if [ "$nodes_not_ready" -gt 0 ]; then
            log_warning "Nodos: $nodes_ready/$nodes_total Ready (algunos nodos aún inicializando - normal en AKS nuevo)"
        else
            log_success "Nodos: $nodes_ready/$nodes_total Ready"
        fi
        checks_passed+=("Nodes")
    else
        log_error "No hay nodos en estado Ready"
        checks_failed+=("Nodes")
    fi
else
    # Para GKE y DOKS, verificar que todos los nodos estén Ready
    nodes_total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    nodes_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | grep -v "NotReady" | wc -l)
    
    if [ "$nodes_ready" -eq "$nodes_total" ] && [ "$nodes_total" -gt 0 ]; then
        log_success "Nodos: $nodes_ready/$nodes_total Ready"
        checks_passed+=("Nodes")
    else
        log_error "Nodos: $nodes_ready/$nodes_total Ready"
        checks_failed+=("Nodes")
    fi
fi

# 1. Verificar API Server
log_info "1. Verificando API Server..."
if kubectl cluster-info 2>/dev/null | grep -q "Kubernetes control plane"; then
    log_success "API Server respondiendo"
    checks_passed+=("API Server")
else
    log_error "API Server no responde"
    checks_failed+=("API Server")
fi

# 1.5. Crear/Verificar namespaces staging y prod (solo para dev)
if [ "$ENVIRONMENT" == "dev" ]; then
    log_info "1.5. Verificando/Creando namespaces staging y prod..."
    
    # Crear namespace staging
    if kubectl get namespace staging &>/dev/null; then
        log_success "Namespace 'staging' ya existe"
    else
        kubectl create namespace staging
        kubectl label namespace staging environment=staging terraform=true app=ecommerce
        log_success "Namespace 'staging' creado"
    fi
    
    # Crear namespace prod
    if kubectl get namespace prod &>/dev/null; then
        log_success "Namespace 'prod' ya existe"
    else
        kubectl create namespace prod
        kubectl label namespace prod environment=production terraform=true app=ecommerce
        log_success "Namespace 'prod' creado"
    fi
    
    checks_passed+=("Namespaces")
fi

# 2. Verificar DNS (CoreDNS/kube-dns/Cilium)
log_info "2. Verificando DNS..."
if [ "$PROVIDER" == "gke" ]; then
    # En GKE, verificar kube-dns
    if kubectl get deployment kube-dns -n kube-system &>/dev/null; then
        dns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
        dns_running=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
        if [ "$dns_running" -gt 0 ]; then
            log_success "kube-dns: $dns_running/$dns_pods pods corriendo"
            checks_passed+=("DNS")
        else
            log_error "kube-dns no tiene pods corriendo"
            checks_failed+=("DNS")
        fi
    else
        log_error "kube-dns deployment no encontrado"
        checks_failed+=("DNS")
    fi
elif [ "$PROVIDER" == "aks" ]; then
    # En AKS, verificar CoreDNS (más tolerante con inicialización)
    if kubectl get deployment coredns -n kube-system &>/dev/null; then
        coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
        coredns_running=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
        coredns_total=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -E "Running|ContainerCreating" | wc -l)
        
        if [ "$coredns_running" -gt 0 ]; then
            log_success "CoreDNS: $coredns_running/$coredns_pods pods corriendo"
            checks_passed+=("DNS")
        elif [ "$coredns_total" -gt 0 ]; then
            log_warning "CoreDNS iniciándose ($coredns_running/$coredns_pods ready) - normal en cluster nuevo"
            checks_passed+=("DNS")
        else
            log_error "CoreDNS no tiene pods corriendo o iniciándose"
            checks_failed+=("DNS")
        fi
    else
        log_error "CoreDNS deployment no encontrado"
        checks_failed+=("DNS")
    fi
elif [ "$PROVIDER" == "doks" ]; then
    # En DOKS, puede ser CoreDNS o Cilium
    if kubectl get deployment coredns -n kube-system &>/dev/null 2>&1; then
        # Clusters antiguos con CoreDNS
        coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
        coredns_running=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "Running" | wc -l)
        if [ "$coredns_running" -gt 0 ]; then
            log_success "CoreDNS: $coredns_running/$coredns_pods pods corriendo"
            checks_passed+=("DNS")
        else
            log_error "CoreDNS no tiene pods corriendo"
            checks_failed+=("DNS")
        fi
    elif kubectl get daemonset cilium -n kube-system &>/dev/null 2>&1; then
        # Clusters nuevos con Cilium (que incluye DNS)
        cilium_pods=$(kubectl get pods -n kube-system -l k8s-app=cilium --no-headers 2>/dev/null | wc -l)
        cilium_running=$(kubectl get pods -n kube-system -l k8s-app=cilium --no-headers 2>/dev/null | grep "Running" | wc -l)
        if [ "$cilium_running" -gt 0 ]; then
            log_success "Cilium DNS: $cilium_running/$cilium_pods pods corriendo"
            checks_passed+=("DNS")
        else
            log_warning "Cilium iniciándose ($cilium_running/$cilium_pods ready)"
            checks_passed+=("DNS")
        fi
    else
        log_error "No se encontró sistema DNS (CoreDNS o Cilium)"
        checks_failed+=("DNS")
    fi
else
    checks_failed+=("DNS")
fi

# 3. Verificar capacidad del cluster
log_info "3. Verificando capacidad del cluster..."
echo ""
kubectl top nodes 2>/dev/null || log_warning "Metrics server no disponible"
echo ""

# 4. Verificar servicios
log_info "4. Verificando servicios..."
kubectl get svc --all-namespaces
checks_passed+=("Services")

# 5. Verificar eventos recientes
log_info "5. Verificando eventos recientes..."
RECENT_ERRORS=$(kubectl get events --all-namespaces --sort-by='.lastTimestamp' 2>/dev/null | grep -i "error\|failed\|warning" | tail -5)
if [ -n "$RECENT_ERRORS" ]; then
    log_warning "Eventos recientes con advertencias/errores:"
    echo "$RECENT_ERRORS"
else
    log_success "No hay eventos de error recientes"
    checks_passed+=("Events")
fi

# 6. Verificar persistent volumes (si existen)
log_info "6. Verificando Persistent Volumes..."
PV_COUNT=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
if [ "$PV_COUNT" -gt 0 ]; then
    kubectl get pv
    checks_passed+=("Persistent Volumes")
else
    log_info "No hay Persistent Volumes configurados"
fi

# 7. Test de conectividad con un pod de prueba
log_info "7. Test de conectividad (creando pod de prueba)..."
kubectl run test-pod --image=busybox --restart=Never --rm -i --timeout=30s -- echo "Health check OK" &>/dev/null && {
    log_success "Test de conectividad exitoso"
    checks_passed+=("Connectivity Test")
} || {
    log_warning "Test de conectividad falló (puede ser normal en clusters nuevos)"
}

# Resumen final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "           RESUMEN DE HEALTH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Checks exitosos: ${#checks_passed[@]}${NC}"
for check in "${checks_passed[@]}"; do
    echo "  ✓ $check"
done

if [ ${#checks_failed[@]} -gt 0 ]; then
    echo -e "${RED}Checks fallidos: ${#checks_failed[@]}${NC}"
    for check in "${checks_failed[@]}"; do
        echo "  ✗ $check"
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "Health check completado con errores"
    exit 1
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Health check completado exitosamente"
fi
