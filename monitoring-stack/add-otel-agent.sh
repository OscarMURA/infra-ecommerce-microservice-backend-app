#!/bin/bash
# add-otel-agent.sh
# Agrega el agente OpenTelemetry a los microservicios de forma no invasiva
# Usa init container para descargar el agente y lo monta en el contenedor principal

set -e

NAMESPACE="${1:-prod}"
OTEL_AGENT_VERSION="1.32.0"
JAEGER_ENDPOINT="http://jaeger-collector.monitoring.svc.cluster.local:4317"

echo "============================================"
echo "  Agregando OpenTelemetry Agent"
echo "  Namespace: ${NAMESPACE}"
echo "============================================"

# Verificar Jaeger
if ! kubectl get deployment jaeger -n monitoring > /dev/null 2>&1; then
    echo "❌ Jaeger no está desplegado"
    exit 1
fi
echo "✅ Jaeger encontrado"

# Servicios a instrumentar con sus puertos
declare -A SERVICES
SERVICES["user-service"]="8082"
SERVICES["order-service"]="8081"
SERVICES["product-service"]="8083"
SERVICES["payment-service"]="8084"
SERVICES["shipping-service"]="8085"
SERVICES["favourite-service"]="8086"

for SERVICE in "${!SERVICES[@]}"; do
    PORT="${SERVICES[$SERVICE]}"
    
    echo ""
    echo "🔧 Configurando ${SERVICE}..."
    
    if ! kubectl get deployment ${SERVICE} -n ${NAMESPACE} > /dev/null 2>&1; then
        echo "  ⚠️  ${SERVICE} no encontrado, saltando..."
        continue
    fi
    
    # Obtener la imagen actual
    CURRENT_IMAGE=$(kubectl get deployment ${SERVICE} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}')
    echo "  📦 Imagen actual: ${CURRENT_IMAGE}"
    
    # Crear archivo de patch temporal
    PATCH_FILE=$(mktemp)
    cat > ${PATCH_FILE} <<EOF
spec:
  template:
    spec:
      initContainers:
      - name: otel-agent-init
        image: curlimages/curl:8.5.0
        command:
        - sh
        - -c
        - |
          curl -sL -o /otel/opentelemetry-javaagent.jar \
            https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar
          ls -la /otel/
        volumeMounts:
        - name: otel-agent-volume
          mountPath: /otel
      containers:
      - name: ${SERVICE}
        image: ${CURRENT_IMAGE}
        env:
        - name: SERVER_PORT
          value: "${PORT}"
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: SPRING_CLOUD_CONFIG_ENABLED
          value: "false"
        - name: JAVA_TOOL_OPTIONS
          value: "-javaagent:/otel/opentelemetry-javaagent.jar"
        - name: OTEL_SERVICE_NAME
          value: "${SERVICE}"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "${JAEGER_ENDPOINT}"
        - name: OTEL_EXPORTER_OTLP_PROTOCOL
          value: "grpc"
        - name: OTEL_TRACES_EXPORTER
          value: "otlp"
        - name: OTEL_METRICS_EXPORTER
          value: "none"
        - name: OTEL_LOGS_EXPORTER
          value: "none"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.namespace=${NAMESPACE},deployment.environment=${NAMESPACE}"
        volumeMounts:
        - name: otel-agent-volume
          mountPath: /otel
          readOnly: true
      volumes:
      - name: otel-agent-volume
        emptyDir: {}
EOF

    # Aplicar el patch
    if kubectl patch deployment ${SERVICE} -n ${NAMESPACE} --patch-file=${PATCH_FILE} 2>/dev/null; then
        echo "  ✅ ${SERVICE} instrumentado con OpenTelemetry"
    else
        echo "  ❌ Error al parchear ${SERVICE}"
    fi
    
    rm -f ${PATCH_FILE}
done

echo ""
echo "⏳ Esperando a que los pods se reinicien..."
sleep 30

# Verificar estado
echo ""
echo "============================================"
echo "  Estado de los pods en ${NAMESPACE}"
echo "============================================"
kubectl get pods -n ${NAMESPACE}

# Mostrar URL de Jaeger
JAEGER_IP=$(kubectl get svc jaeger-query -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
echo ""
echo "============================================"
echo "  Tracing Configurado!"
echo "============================================"
echo ""
echo "📊 Jaeger UI: http://${JAEGER_IP}:16686"
echo ""
echo "Para generar traces, haz requests a los servicios."
echo "Luego ve a Jaeger UI y selecciona un servicio."
echo ""
