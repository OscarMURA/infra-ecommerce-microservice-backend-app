#!/usr/bin/env bash
set -euo pipefail

# Script para configurar Minikube en la VM después de la creación
# Este script se ejecuta desde Jenkins para configurar Minikube específicamente

VM_IP="${1:-}"
if [[ -z "${VM_IP}" ]]; then
  echo "❌ Uso: $0 <VM_IP>" >&2
  exit 1
fi

echo "🔧 Configurando Minikube en VM ${VM_IP}..."

# Esperar a que la VM esté lista
echo "⏳ Esperando que la VM esté lista..."
for i in $(seq 1 30); do
  if sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${VM_IP}" "echo VM ready" >/dev/null 2>&1; then
    echo "✅ VM lista para configuración"
    break
  fi
  echo "   reintentando ($i/30)..."
  sleep 10
done

# Configurar Minikube y Google Cloud SDK
echo "🚀 Configurando Minikube y Google Cloud SDK..."
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${VM_IP}" << 'EOF'
set -euo pipefail

echo "📦 Instalando Google Cloud SDK..."
if ! command -v gcloud &> /dev/null; then
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  sudo apt-get update
  sudo apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
  gcloud config set core/disable_usage_reporting true
  gcloud config set component_manager/disable_update_check true
  echo "✅ Google Cloud SDK instalado"
else
  echo "✅ Google Cloud SDK ya está instalado"
fi

echo "🔍 Verificando estado de Minikube..."
if minikube status >/dev/null 2>&1; then
  echo "✅ Minikube ya está ejecutándose"
else
  echo "🚀 Iniciando Minikube..."
  minikube start --driver=docker --memory=3072 --cpus=2 --disk-size=20g
fi

echo "📊 Estado de Minikube:"
minikube status

echo "🔧 Configurando kubectl..."
minikube kubectl -- get nodes || true

echo "🌐 Servicios disponibles:"
minikube service list || true

echo "📋 Información del cluster:"
minikube kubectl -- get all || true

echo "✅ Minikube y Google Cloud SDK configurados exitosamente"
EOF

echo "🎉 Configuración de Minikube completada en ${VM_IP}"
