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

# Configurar Minikube (Docker y Google Cloud SDK ya están instalados)
echo "🚀 Instalando kubectl y Minikube..."
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${VM_IP}" << 'EOF'
set -euo pipefail

echo "📦 Instalando kubectl..."
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  echo "✅ kubectl instalado"
else
  echo "✅ kubectl ya está instalado"
fi

echo "📦 Instalando Minikube..."
if ! command -v minikube &> /dev/null; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
  echo "✅ Minikube instalado"
else
  echo "✅ Minikube ya está instalado"
fi

echo "🔧 Configurando Minikube..."
minikube config set driver docker
minikube config set memory 3072
minikube config set cpus 2
minikube config set disk-size 20g

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

echo "✅ Minikube configurado exitosamente"
EOF

echo "🎉 Configuración de Minikube completada en ${VM_IP}"
