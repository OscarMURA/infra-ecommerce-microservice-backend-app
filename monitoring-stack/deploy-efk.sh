#!/bin/bash
# deploy-efk.sh - Script para desplegar el EFK Stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"

echo "============================================"
echo "  Desplegando EFK Stack para Logging"
echo "============================================"

# Verificar conexión al cluster
echo ""
echo "📋 Verificando conexión al cluster..."
kubectl cluster-info > /dev/null 2>&1 || { echo "❌ No se puede conectar al cluster"; exit 1; }
echo "✅ Conexión al cluster OK"

# Crear namespace si no existe
echo ""
echo "📋 Verificando namespace ${NAMESPACE}..."
kubectl get namespace ${NAMESPACE} > /dev/null 2>&1 || kubectl create namespace ${NAMESPACE}
echo "✅ Namespace ${NAMESPACE} listo"

# Desplegar Elasticsearch
echo ""
echo "🔍 Desplegando Elasticsearch..."
kubectl apply -f "${SCRIPT_DIR}/efk-stack/elasticsearch.yaml"
echo "✅ Elasticsearch desplegado"

# Esperar a que Elasticsearch esté listo
echo ""
echo "⏳ Esperando a que Elasticsearch esté listo (puede tomar 2-3 minutos)..."
kubectl rollout status deployment/elasticsearch -n ${NAMESPACE} --timeout=300s || true

# Verificar que Elasticsearch está corriendo
echo ""
echo "📋 Verificando Elasticsearch..."
sleep 10
kubectl get pods -n ${NAMESPACE} -l app=elasticsearch

# Desplegar Kibana
echo ""
echo "📊 Desplegando Kibana..."
kubectl apply -f "${SCRIPT_DIR}/efk-stack/kibana.yaml"
echo "✅ Kibana desplegado"

# Esperar a que Kibana esté listo
echo ""
echo "⏳ Esperando a que Kibana esté listo..."
kubectl rollout status deployment/kibana -n ${NAMESPACE} --timeout=300s || true

# Desplegar Fluentd
echo ""
echo "📝 Desplegando Fluentd DaemonSet..."
kubectl apply -f "${SCRIPT_DIR}/efk-stack/fluentd.yaml"
echo "✅ Fluentd desplegado"

# Esperar a que Fluentd esté listo
echo ""
echo "⏳ Esperando a que Fluentd esté listo..."
kubectl rollout status daemonset/fluentd -n ${NAMESPACE} --timeout=180s || true

# Mostrar estado de los pods
echo ""
echo "============================================"
echo "  Estado del EFK Stack"
echo "============================================"
kubectl get pods -n ${NAMESPACE} -l 'app in (elasticsearch, kibana, fluentd)'

# Obtener URLs de acceso
echo ""
echo "============================================"
echo "  URLs de Acceso"
echo "============================================"

echo ""
echo "⏳ Esperando IP externa de Kibana..."
for i in {1..30}; do
    KIBANA_IP=$(kubectl get svc kibana -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$KIBANA_IP" ]; then
        break
    fi
    echo "  Intento $i/30 - Esperando IP..."
    sleep 10
done

if [ -n "$KIBANA_IP" ]; then
    echo ""
    echo "🎉 EFK Stack desplegado exitosamente!"
    echo ""
    echo "📊 Kibana: http://${KIBANA_IP}:5601"
    echo ""
    echo "============================================"
    echo "  Próximos pasos en Kibana:"
    echo "============================================"
    echo "1. Ir a Stack Management > Data Views"
    echo "2. Crear un Data View con patrón: ecommerce-logs-*"
    echo "3. Seleccionar @timestamp como campo de tiempo"
    echo "4. Ir a Discover para ver los logs"
    echo ""
else
    echo ""
    echo "⚠️  La IP de Kibana aún no está disponible."
    echo "    Ejecuta: kubectl get svc kibana -n ${NAMESPACE}"
    echo ""
fi

echo "============================================"
echo "  Comandos útiles:"
echo "============================================"
echo "# Ver pods del EFK Stack:"
echo "kubectl get pods -n ${NAMESPACE} -l 'app in (elasticsearch, kibana, fluentd)'"
echo ""
echo "# Ver logs de Fluentd:"
echo "kubectl logs -n ${NAMESPACE} -l app=fluentd --tail=50"
echo ""
echo "# Ver logs de Elasticsearch:"
echo "kubectl logs -n ${NAMESPACE} -l app=elasticsearch --tail=50"
echo ""
echo "# Verificar índices en Elasticsearch:"
echo "kubectl exec -n ${NAMESPACE} \$(kubectl get pod -n ${NAMESPACE} -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -s localhost:9200/_cat/indices"
echo ""
