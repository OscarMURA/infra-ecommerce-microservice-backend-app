#!/bin/bash
# Script para configurar Grafana con Prometheus datasource y dashboards

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables de configuración
GRAFANA_URL="${GRAFANA_URL:-http://34.121.2.178}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin123}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== Configuración de Grafana ===${NC}"
echo -e "URL: ${GRAFANA_URL}"
echo -e "Usuario: ${GRAFANA_USER}"

# Verificar conectividad con Grafana
echo -e "\n${YELLOW}Verificando conectividad con Grafana...${NC}"
if ! curl -s --max-time 5 "${GRAFANA_URL}/api/health" | grep -q "ok"; then
    echo -e "${RED}Error: No se puede conectar a Grafana en ${GRAFANA_URL}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Grafana está disponible${NC}"

# Configurar datasource de Prometheus
echo -e "\n${YELLOW}Configurando datasource de Prometheus...${NC}"

# URL interna del prometheus-server en el cluster
PROMETHEUS_URL="http://prometheus-server.monitoring.svc.cluster.local:80"

DATASOURCE_PAYLOAD=$(cat <<EOF
{
  "name": "prometheus",
  "type": "prometheus",
  "url": "${PROMETHEUS_URL}",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "httpMethod": "POST",
    "manageAlerts": true,
    "prometheusType": "Prometheus",
    "prometheusVersion": "2.48.0"
  }
}
EOF
)

# Crear o actualizar el datasource
RESPONSE=$(curl -s -X POST \
  "${GRAFANA_URL}/api/datasources" \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d "${DATASOURCE_PAYLOAD}" 2>&1)

if echo "$RESPONSE" | grep -q "Datasource added\|name already exists\|id"; then
    echo -e "${GREEN}✓ Datasource de Prometheus configurado${NC}"
else
    echo -e "${YELLOW}Respuesta del servidor: ${RESPONSE}${NC}"
    # Intentar actualizar si ya existe
    echo -e "${YELLOW}Intentando actualizar datasource existente...${NC}"
    
    # Obtener el ID del datasource existente
    DS_ID=$(curl -s -X GET \
      "${GRAFANA_URL}/api/datasources/name/prometheus" \
      -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    
    if [ -n "$DS_ID" ]; then
        DATASOURCE_PAYLOAD=$(cat <<EOF
{
  "id": ${DS_ID},
  "uid": "prometheus",
  "name": "prometheus",
  "type": "prometheus",
  "url": "${PROMETHEUS_URL}",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "httpMethod": "POST",
    "manageAlerts": true,
    "prometheusType": "Prometheus",
    "prometheusVersion": "2.48.0"
  }
}
EOF
)
        curl -s -X PUT \
          "${GRAFANA_URL}/api/datasources/${DS_ID}" \
          -H "Content-Type: application/json" \
          -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
          -d "${DATASOURCE_PAYLOAD}" > /dev/null
        echo -e "${GREEN}✓ Datasource actualizado${NC}"
    fi
fi

# Importar dashboards
echo -e "\n${YELLOW}Importando dashboards...${NC}"

DASHBOARD_DIR="${SCRIPT_DIR}/grafana-dashboards"

if [ -d "$DASHBOARD_DIR" ]; then
    for dashboard_file in "$DASHBOARD_DIR"/*.json; do
        if [ -f "$dashboard_file" ]; then
            dashboard_name=$(basename "$dashboard_file" .json)
            echo -e "${BLUE}Importando: ${dashboard_name}${NC}"
            
            # Crear payload para importar dashboard
            DASHBOARD_CONTENT=$(cat "$dashboard_file")
            
            IMPORT_PAYLOAD=$(cat <<EOF
{
  "dashboard": ${DASHBOARD_CONTENT},
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "prometheus"
    }
  ],
  "folderId": 0
}
EOF
)
            
            IMPORT_RESPONSE=$(curl -s -X POST \
              "${GRAFANA_URL}/api/dashboards/db" \
              -H "Content-Type: application/json" \
              -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
              -d "${IMPORT_PAYLOAD}" 2>&1)
            
            if echo "$IMPORT_RESPONSE" | grep -q '"status":"success"\|"uid"'; then
                echo -e "${GREEN}✓ Dashboard '${dashboard_name}' importado correctamente${NC}"
                # Extraer URL del dashboard
                DASHBOARD_URL=$(echo "$IMPORT_RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | sed 's/"url":"//;s/"//')
                if [ -n "$DASHBOARD_URL" ]; then
                    echo -e "  ${BLUE}URL: ${GRAFANA_URL}${DASHBOARD_URL}${NC}"
                fi
            else
                echo -e "${RED}✗ Error importando '${dashboard_name}'${NC}"
                echo -e "${YELLOW}  Respuesta: ${IMPORT_RESPONSE}${NC}"
            fi
        fi
    done
else
    echo -e "${YELLOW}No se encontró el directorio de dashboards: ${DASHBOARD_DIR}${NC}"
fi

# Importar dashboards de la comunidad (opcionales)
echo -e "\n${YELLOW}Importando dashboards populares de la comunidad...${NC}"

# JVM Dashboard (ID: 4701)
echo -e "${BLUE}Importando JVM Dashboard (Micrometer)...${NC}"
JVM_IMPORT=$(curl -s -X POST \
  "${GRAFANA_URL}/api/dashboards/import" \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d '{
    "dashboard": {"id": 4701},
    "overwrite": true,
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "prometheus"
      }
    ],
    "folderId": 0
  }' 2>&1)

if echo "$JVM_IMPORT" | grep -q '"imported":true\|"uid"'; then
    echo -e "${GREEN}✓ JVM Dashboard importado${NC}"
else
    echo -e "${YELLOW}⚠ JVM Dashboard no se pudo importar (puede que no esté disponible offline)${NC}"
fi

# Spring Boot Dashboard (ID: 11378)
echo -e "${BLUE}Importando Spring Boot Dashboard...${NC}"
SPRING_IMPORT=$(curl -s -X POST \
  "${GRAFANA_URL}/api/dashboards/import" \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d '{
    "dashboard": {"id": 11378},
    "overwrite": true,
    "inputs": [
      {
        "name": "DS_PROMETHEUS",
        "type": "datasource",
        "pluginId": "prometheus",
        "value": "prometheus"
      }
    ],
    "folderId": 0
  }' 2>&1)

if echo "$SPRING_IMPORT" | grep -q '"imported":true\|"uid"'; then
    echo -e "${GREEN}✓ Spring Boot Dashboard importado${NC}"
else
    echo -e "${YELLOW}⚠ Spring Boot Dashboard no se pudo importar (puede que no esté disponible offline)${NC}"
fi

echo -e "\n${GREEN}=== Configuración completada ===${NC}"
echo -e "${BLUE}Accede a Grafana:${NC}"
echo -e "  URL: ${GRAFANA_URL}"
echo -e "  Usuario: ${GRAFANA_USER}"
echo -e "  Contraseña: ${GRAFANA_PASSWORD}"
echo -e "\n${BLUE}Dashboards disponibles:${NC}"
echo -e "  - E-Commerce Microservices: ${GRAFANA_URL}/d/ecommerce-microservices"
echo -e "\n${YELLOW}Nota: Pueden pasar unos minutos hasta que Prometheus recolecte métricas de los pods.${NC}"
