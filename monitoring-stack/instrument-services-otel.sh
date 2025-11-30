#!/bin/bash
# instrument-services-otel.sh
# Instrumenta los microservicios con OpenTelemetry de forma simple
# Usa un ConfigMap con el agente pre-descargado

set -e

NAMESPACE="${1:-prod}"
OTEL_AGENT_VERSION="1.32.0"

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

# Lista de servicios
SERVICES=(
    "user-service"
    "order-service"
    "product-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
)

# Instrumentar cada servicio agregando variables de entorno
for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "🔧 Instrumentando ${SERVICE}..."
    
    if ! kubectl get deployment ${SERVICE} -n ${NAMESPACE} > /dev/null 2>&1; then
        echo "  ⚠️  ${SERVICE} no encontrado en ${NAMESPACE}, saltando..."
        continue
    fi
    
    # Agregar variables de entorno para OpenTelemetry
    kubectl set env deployment/${SERVICE} -n ${NAMESPACE} \
        OTEL_SERVICE_NAME="${SERVICE}" \
        OTEL_EXPORTER_OTLP_ENDPOINT="http://jaeger-collector.monitoring.svc.cluster.local:4317" \
        OTEL_EXPORTER_OTLP_PROTOCOL="grpc" \
        OTEL_TRACES_EXPORTER="otlp" \
        OTEL_METRICS_EXPORTER="none" \
        OTEL_LOGS_EXPORTER="none" \
        OTEL_RESOURCE_ATTRIBUTES="service.namespace=${NAMESPACE},deployment.environment=${NAMESPACE}" \
        2>/dev/null && echo "  ✅ Variables OTEL agregadas a ${SERVICE}" || echo "  ⚠️  Error con ${SERVICE}"
done

echo ""
echo "============================================"
echo "  Variables de entorno configuradas"
echo "============================================"
echo ""
echo "⚠️  NOTA: Para que el tracing funcione completamente,"
echo "   los servicios necesitan el agente de OpenTelemetry."
echo ""
echo "   Hay dos opciones:"
echo ""
echo "   OPCIÓN A (Recomendada): Agregar dependencia Spring Cloud Sleuth"
echo "   OPCIÓN B: Modificar los Dockerfiles para incluir el agente OTEL"
echo ""
echo "   Sin embargo, las variables de entorno ya están configuradas"
echo "   para cuando el agente esté disponible."
echo ""

# Mostrar Jaeger UI
JAEGER_IP=$(kubectl get svc jaeger-query -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$JAEGER_IP" ]; then
    echo "📊 Jaeger UI: http://${JAEGER_IP}:16686"
fi
echo ""
