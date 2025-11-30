#!/bin/bash
# patch-deployments-otel.sh
# Agrega el agente de OpenTelemetry a los microservicios existentes
# SIN necesidad de modificar código ni reconstruir imágenes

set -e

NAMESPACE="${1:-prod}"
OTEL_AGENT_VERSION="1.32.0"
JAEGER_ENDPOINT="http://jaeger-collector.monitoring.svc.cluster.local:4317"

# Lista de servicios a instrumentar
SERVICES=(
    "user-service"
    "order-service"
    "product-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
)

echo "============================================"
echo "  Instrumentando servicios con OpenTelemetry"
echo "  Namespace: ${NAMESPACE}"
echo "============================================"

# Verificar que Jaeger está corriendo
echo ""
echo "📋 Verificando Jaeger..."
if ! kubectl get deployment jaeger -n monitoring > /dev/null 2>&1; then
    echo "❌ Jaeger no está desplegado. Ejecuta primero: ./deploy-jaeger.sh"
    exit 1
fi
echo "✅ Jaeger encontrado"

# Función para parchear un deployment
patch_deployment() {
    local SERVICE=$1
    local NS=$2
    
    echo ""
    echo "🔧 Parcheando ${SERVICE} en namespace ${NS}..."
    
    # Verificar si el deployment existe
    if ! kubectl get deployment ${SERVICE} -n ${NS} > /dev/null 2>&1; then
        echo "  ⚠️  Deployment ${SERVICE} no encontrado en ${NS}, saltando..."
        return
    fi
    
    # Crear el patch JSON
    PATCH=$(cat <<EOF
{
  "spec": {
    "template": {
      "spec": {
        "initContainers": [
          {
            "name": "otel-agent-init",
            "image": "busybox:1.36",
            "command": ["sh", "-c", "wget -O /otel/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar"],
            "volumeMounts": [
              {
                "name": "otel-agent",
                "mountPath": "/otel"
              }
            ]
          }
        ],
        "containers": [
          {
            "name": "${SERVICE}",
            "env": [
              {
                "name": "JAVA_TOOL_OPTIONS",
                "value": "-javaagent:/otel/opentelemetry-javaagent.jar"
              },
              {
                "name": "OTEL_SERVICE_NAME",
                "value": "${SERVICE}"
              },
              {
                "name": "OTEL_EXPORTER_OTLP_ENDPOINT",
                "value": "${JAEGER_ENDPOINT}"
              },
              {
                "name": "OTEL_EXPORTER_OTLP_PROTOCOL",
                "value": "grpc"
              },
              {
                "name": "OTEL_TRACES_EXPORTER",
                "value": "otlp"
              },
              {
                "name": "OTEL_METRICS_EXPORTER",
                "value": "none"
              },
              {
                "name": "OTEL_LOGS_EXPORTER",
                "value": "none"
              },
              {
                "name": "OTEL_RESOURCE_ATTRIBUTES",
                "value": "service.namespace=${NS},deployment.environment=${NS}"
              }
            ],
            "volumeMounts": [
              {
                "name": "otel-agent",
                "mountPath": "/otel"
              }
            ]
          }
        ],
        "volumes": [
          {
            "name": "otel-agent",
            "emptyDir": {}
          }
        ]
      }
    }
  }
}
EOF
)

    # Aplicar el patch usando strategic merge
    if kubectl patch deployment ${SERVICE} -n ${NS} --type=strategic -p "${PATCH}" 2>/dev/null; then
        echo "  ✅ ${SERVICE} parcheado exitosamente"
    else
        echo "  ⚠️  Error al parchear ${SERVICE}, intentando método alternativo..."
        # Método alternativo: agregar env vars directamente
        kubectl set env deployment/${SERVICE} -n ${NS} \
            JAVA_TOOL_OPTIONS="-javaagent:/otel/opentelemetry-javaagent.jar" \
            OTEL_SERVICE_NAME="${SERVICE}" \
            OTEL_EXPORTER_OTLP_ENDPOINT="${JAEGER_ENDPOINT}" \
            OTEL_TRACES_EXPORTER="otlp" \
            OTEL_METRICS_EXPORTER="none" \
            2>/dev/null || echo "  ❌ No se pudo parchear ${SERVICE}"
    fi
}

# Parchear cada servicio
for SERVICE in "${SERVICES[@]}"; do
    patch_deployment "$SERVICE" "$NAMESPACE"
done

# Esperar a que los pods se reinicien
echo ""
echo "⏳ Esperando a que los pods se reinicien (60 segundos)..."
sleep 60

# Mostrar estado
echo ""
echo "============================================"
echo "  Estado de los deployments en ${NAMESPACE}"
echo "============================================"
kubectl get pods -n ${NAMESPACE} -l 'app in (user-service,order-service,product-service,payment-service,shipping-service,favourite-service)'

# Obtener IP de Jaeger
JAEGER_IP=$(kubectl get svc jaeger-query -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

echo ""
echo "============================================"
echo "  ¡Instrumentación completada!"
echo "============================================"
echo ""
echo "📊 Jaeger UI: http://${JAEGER_IP}:16686"
echo ""
echo "Para ver traces:"
echo "1. Genera tráfico a los servicios"
echo "2. Abre Jaeger UI"
echo "3. Selecciona un servicio en el dropdown"
echo "4. Click en 'Find Traces'"
echo ""
echo "Servicios instrumentados:"
for SERVICE in "${SERVICES[@]}"; do
    echo "  - ${SERVICE}"
done
echo ""
