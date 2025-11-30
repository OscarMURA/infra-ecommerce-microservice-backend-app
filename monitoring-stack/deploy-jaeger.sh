#!/bin/bash
# deploy-jaeger.sh - Script para desplegar Jaeger Tracing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"

echo "============================================"
echo "  Desplegando Jaeger - Tracing Distribuido"
echo "============================================"

# Verificar conexión al cluster
echo ""
echo "📋 Verificando conexión al cluster..."
kubectl cluster-info > /dev/null 2>&1 || { echo "❌ No se puede conectar al cluster"; exit 1; }
echo "✅ Conexión al cluster OK"

# Desplegar Jaeger
echo ""
echo "🔍 Desplegando Jaeger All-in-One..."
kubectl apply -f "${SCRIPT_DIR}/jaeger/jaeger-all-in-one.yaml"
echo "✅ Jaeger desplegado"

# Esperar a que Jaeger esté listo
echo ""
echo "⏳ Esperando a que Jaeger esté listo..."
kubectl rollout status deployment/jaeger -n ${NAMESPACE} --timeout=180s || true

# Mostrar estado
echo ""
echo "📋 Estado de Jaeger:"
kubectl get pods -n ${NAMESPACE} -l app=jaeger

# Obtener IP de Jaeger UI
echo ""
echo "⏳ Esperando IP externa de Jaeger UI..."
for i in {1..30}; do
    JAEGER_IP=$(kubectl get svc jaeger-query -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$JAEGER_IP" ]; then
        break
    fi
    echo "  Intento $i/30 - Esperando IP..."
    sleep 10
done

if [ -n "$JAEGER_IP" ]; then
    echo ""
    echo "🎉 Jaeger desplegado exitosamente!"
    echo ""
    echo "📊 Jaeger UI: http://${JAEGER_IP}:16686"
    echo ""
else
    echo ""
    echo "⚠️  La IP de Jaeger aún no está disponible."
    echo "    Ejecuta: kubectl get svc jaeger-query -n ${NAMESPACE}"
fi

echo ""
echo "============================================"
echo "  Servicios de Jaeger"
echo "============================================"
kubectl get svc -n ${NAMESPACE} -l app=jaeger

echo ""
echo "============================================"
echo "  Próximo paso: Instrumentar servicios"
echo "============================================"
echo "Ejecuta el script para agregar OpenTelemetry a los microservicios:"
echo ""
echo "  ./patch-deployments-otel.sh"
echo ""
