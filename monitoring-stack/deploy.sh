#!/bin/bash

# ============================================
# Script para desplegar Prometheus + Grafana
# en cluster GKE existente usando Terraform
# ============================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

# Función para imprimir mensajes
print_msg() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     📊 MONITORING STACK DEPLOYMENT                           ║"
echo "║        Prometheus + Grafana en GKE                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Verificar prerequisitos
check_prerequisites() {
    print_msg "Verificando prerequisitos..."
    
    # Verificar gcloud
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud no está instalado. Instálalo desde: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    print_success "✓ gcloud instalado"

    # Verificar terraform
    if ! command -v terraform &> /dev/null; then
        print_error "terraform no está instalado. Instálalo desde: https://www.terraform.io/downloads"
        exit 1
    fi
    print_success "✓ terraform instalado"

    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    print_success "✓ kubectl instalado"

    # Verificar autenticación de gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 &> /dev/null; then
        print_warning "No estás autenticado en gcloud. Ejecutando gcloud auth login..."
        gcloud auth login
    fi
    print_success "✓ gcloud autenticado"
}

# Conectar al cluster GKE
connect_cluster() {
    print_msg "Conectando al cluster GKE..."
    
    # Leer variables del tfvars
    PROJECT_ID=$(grep 'project_id' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
    ZONE=$(grep 'zone' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
    CLUSTER_NAME=$(grep 'cluster_name' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
    
    print_msg "  Proyecto: ${PROJECT_ID}"
    print_msg "  Zona: ${ZONE}"
    print_msg "  Cluster: ${CLUSTER_NAME}"
    
    # Configurar proyecto
    gcloud config set project "${PROJECT_ID}"
    
    # Obtener credenciales del cluster
    gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone "${ZONE}" --project "${PROJECT_ID}"
    
    # Verificar conexión
    if kubectl cluster-info &> /dev/null; then
        print_success "✓ Conectado al cluster ${CLUSTER_NAME}"
    else
        print_error "No se pudo conectar al cluster"
        exit 1
    fi
}

# Aplicar Terraform
apply_terraform() {
    print_msg "Iniciando Terraform..."
    
    cd "${TERRAFORM_DIR}"
    
    # Inicializar Terraform
    print_msg "Inicializando Terraform..."
    terraform init
    
    # Plan
    print_msg "Generando plan de Terraform..."
    terraform plan -out=tfplan
    
    # Preguntar si continuar
    echo ""
    read -p "¿Deseas aplicar este plan? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Aplicando Terraform..."
        terraform apply tfplan
        print_success "✓ Terraform aplicado exitosamente"
    else
        print_warning "Aplicación cancelada por el usuario"
        exit 0
    fi
}

# Verificar despliegue
verify_deployment() {
    print_msg "Verificando despliegue..."
    
    NAMESPACE=$(grep 'monitoring_namespace' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
    
    # Esperar a que los pods estén ready
    print_msg "Esperando a que los pods estén listos..."
    
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n "${NAMESPACE}" --timeout=300s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n "${NAMESPACE}" --timeout=300s 2>/dev/null || true
    
    echo ""
    print_msg "Estado de los pods en namespace ${NAMESPACE}:"
    kubectl get pods -n "${NAMESPACE}"
    
    echo ""
    print_msg "Servicios disponibles:"
    kubectl get svc -n "${NAMESPACE}"
}

# Mostrar información de acceso
show_access_info() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 DESPLIEGUE COMPLETADO                  ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  Para acceder a Grafana (opción 1 - Port Forward):          ║"
    echo "║                                                              ║"
    echo "║    kubectl port-forward svc/grafana 3000:80 -n monitoring   ║"
    echo "║    Luego abre: http://localhost:3000                        ║"
    echo "║                                                              ║"
    echo "║  Para acceder a Prometheus:                                  ║"
    echo "║                                                              ║"
    echo "║    kubectl port-forward svc/prometheus-server 9090:80 -n monitoring ║"
    echo "║    Luego abre: http://localhost:9090                        ║"
    echo "║                                                              ║"
    echo "║  Credenciales Grafana:                                       ║"
    echo "║    Usuario: admin                                            ║"
    echo "║    Password: admin123 (o el configurado en terraform.tfvars)║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Si Grafana tiene LoadBalancer, mostrar IP externa
    EXTERNAL_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$EXTERNAL_IP" ]; then
        echo "🌐 Grafana disponible en: http://${EXTERNAL_IP}"
    fi
}

# Menú principal
main() {
    case "${1:-deploy}" in
        deploy)
            check_prerequisites
            connect_cluster
            apply_terraform
            verify_deployment
            show_access_info
            ;;
        destroy)
            print_warning "Destruyendo stack de monitoring..."
            cd "${TERRAFORM_DIR}"
            terraform destroy
            ;;
        status)
            connect_cluster
            verify_deployment
            show_access_info
            ;;
        port-forward)
            print_msg "Iniciando port-forward para Grafana y Prometheus..."
            kubectl port-forward svc/grafana 3000:80 -n monitoring &
            kubectl port-forward svc/prometheus-server 9090:80 -n monitoring &
            print_success "Port-forward activo:"
            print_success "  Grafana:    http://localhost:3000"
            print_success "  Prometheus: http://localhost:9090"
            wait
            ;;
        *)
            echo "Uso: $0 {deploy|destroy|status|port-forward}"
            echo ""
            echo "  deploy       - Desplegar Prometheus + Grafana"
            echo "  destroy      - Eliminar stack de monitoring"
            echo "  status       - Ver estado actual"
            echo "  port-forward - Crear túneles para acceso local"
            exit 1
            ;;
    esac
}

main "$@"
