#!/bin/bash
# Script para agregar dependencias de Prometheus a todos los microservicios
# Esto permite que los servicios expongan métricas en /actuator/prometheus

SERVICES=(
    "user-service"
    "order-service"
    "product-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
    "service-discovery"
    "api-gateway"
)

BASE_DIR="/home/oscar/Documents/Taller 2 Ingesoft/ecommerce-microservice-backend-app"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Agregando dependencias de Prometheus a microservicios ===${NC}"

for service in "${SERVICES[@]}"; do
    POM_FILE="${BASE_DIR}/${service}/pom.xml"
    
    if [ -f "$POM_FILE" ]; then
        echo -e "${YELLOW}Verificando $service...${NC}"
        
        # Verificar si ya tiene micrometer-registry-prometheus
        if grep -q "micrometer-registry-prometheus" "$POM_FILE"; then
            echo -e "${GREEN}✓ $service ya tiene micrometer-registry-prometheus${NC}"
        else
            echo -e "${BLUE}Agregando micrometer-registry-prometheus a $service...${NC}"
            
            # Buscar la posición después de spring-boot-starter-actuator y agregar la dependencia
            sed -i '/<artifactId>spring-boot-starter-actuator<\/artifactId>/,/<\/dependency>/ {
                /<\/dependency>/a\
\t\t<!-- Prometheus metrics exporter -->\
\t\t<dependency>\
\t\t\t<groupId>io.micrometer</groupId>\
\t\t\t<artifactId>micrometer-registry-prometheus</artifactId>\
\t\t</dependency>
            }' "$POM_FILE"
            
            echo -e "${GREEN}✓ Dependencia agregada a $service${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No se encontró pom.xml para $service${NC}"
    fi
done

echo -e "\n${BLUE}=== Actualizando configuración de application.yml ===${NC}"

# Crear contenido de configuración de management
MANAGEMENT_CONFIG="
# Prometheus and Actuator configuration
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
      base-path: /actuator
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
    prometheus:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: \${spring.application.name}
"

for service in "${SERVICES[@]}"; do
    APP_YML="${BASE_DIR}/${service}/src/main/resources/application.yml"
    
    if [ -f "$APP_YML" ]; then
        echo -e "${YELLOW}Verificando configuración de $service...${NC}"
        
        # Verificar si ya tiene configuración de prometheus
        if grep -q "prometheus:" "$APP_YML" && grep -q "include:.*prometheus" "$APP_YML"; then
            echo -e "${GREEN}✓ $service ya tiene configuración de Prometheus${NC}"
        else
            # Verificar si tiene sección management
            if grep -q "^management:" "$APP_YML"; then
                echo -e "${YELLOW}$service tiene management parcial, revisa manualmente${NC}"
            else
                echo -e "${BLUE}Agregando configuración a $service...${NC}"
                echo "$MANAGEMENT_CONFIG" >> "$APP_YML"
                echo -e "${GREEN}✓ Configuración agregada a $service${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ No se encontró application.yml para $service${NC}"
    fi
done

echo -e "\n${GREEN}=== Proceso completado ===${NC}"
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo -e "1. Revisa los cambios con: git diff"
echo -e "2. Reconstruye las imágenes Docker"
echo -e "3. Vuelve a desplegar los servicios"
echo -e "\n${BLUE}Comandos sugeridos:${NC}"
echo -e "  cd '${BASE_DIR}'"
echo -e "  mvn clean package -DskipTests"
echo -e "  # Luego reconstruir imágenes Docker y desplegar"
