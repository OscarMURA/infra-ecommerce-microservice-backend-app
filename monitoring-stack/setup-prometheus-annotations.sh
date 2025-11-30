#!/bin/bash
# Script para agregar anotaciones de Prometheus a los microservicios

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Configurando anotaciones de Prometheus para microservicios ===${NC}"

# Definir servicios y sus puertos
declare -A SERVICES_PROD=(
    ["user-service"]="8085"
    ["order-service"]="8081"
    ["product-service"]="8083"
    ["payment-service"]="8082"
    ["shipping-service"]="8084"
    ["favourite-service"]="8086"
    ["service-discovery"]="8761"
)

declare -A SERVICES_STAGING=(
    ["user-service"]="8085"
    ["order-service"]="8081"
    ["product-service"]="8083"
    ["payment-service"]="8082"
    ["shipping-service"]="8084"
    ["favourite-service"]="8086"
    ["service-discovery"]="8761"
)

# Función para agregar anotaciones
add_annotations() {
    local namespace=$1
    local service=$2
    local port=$3
    
    echo -e "${YELLOW}Configurando $service en namespace $namespace...${NC}"
    
    # Las aplicaciones Spring Boot exponen métricas en /actuator/prometheus
    kubectl patch deployment "$service" -n "$namespace" --type='json' -p="[
        {
            \"op\": \"add\",
            \"path\": \"/spec/template/metadata/annotations\",
            \"value\": {}
        }
    ]" 2>/dev/null || true
    
    kubectl patch deployment "$service" -n "$namespace" --type='merge' -p="{
        \"spec\": {
            \"template\": {
                \"metadata\": {
                    \"annotations\": {
                        \"prometheus.io/scrape\": \"true\",
                        \"prometheus.io/port\": \"$port\",
                        \"prometheus.io/path\": \"/actuator/prometheus\"
                    }
                }
            }
        }
    }"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $service configurado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠ $service no se pudo configurar (puede que no exista)${NC}"
    fi
}

# Configurar servicios en PROD
echo -e "\n${BLUE}=== Namespace: prod ===${NC}"
for service in "${!SERVICES_PROD[@]}"; do
    add_annotations "prod" "$service" "${SERVICES_PROD[$service]}"
done

# Configurar servicios en STAGING
echo -e "\n${BLUE}=== Namespace: staging ===${NC}"
for service in "${!SERVICES_STAGING[@]}"; do
    add_annotations "staging" "$service" "${SERVICES_STAGING[$service]}"
done

echo -e "\n${GREEN}=== Anotaciones configuradas ===${NC}"
echo -e "${YELLOW}Los pods se reiniciarán automáticamente para aplicar los cambios.${NC}"
echo -e "${YELLOW}Espera unos segundos para que Prometheus descubra los nuevos targets.${NC}"

# Verificar estado
echo -e "\n${BLUE}=== Verificando pods reiniciados ===${NC}"
sleep 5
kubectl get pods -n prod -l app
echo ""
kubectl get pods -n staging -l app
