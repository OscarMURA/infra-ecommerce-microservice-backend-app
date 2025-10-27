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
  echo "🔽 Descargando Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  echo "📁 Instalando Minikube..."
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
  echo "✅ Minikube instalado"
  
  # Verificar que la instalación fue exitosa
  if command -v minikube &> /dev/null; then
    echo "✅ Verificación: Minikube está disponible"
    minikube version
  else
    echo "❌ Error: Minikube no está disponible después de la instalación"
    exit 1
  fi
else
  echo "✅ Minikube ya está instalado"
fi

echo "🔧 Configurando Minikube..."
if command -v minikube &> /dev/null; then
  minikube config set driver docker
  minikube config set memory 3072
  minikube config set cpus 2
  minikube config set disk-size 20g
  echo "✅ Configuración de Minikube completada"
else
  echo "⚠️  Minikube no está instalado aún"
fi

echo "🔍 Verificando estado de Minikube..."
if command -v minikube &> /dev/null && minikube status >/dev/null 2>&1; then
  echo "✅ Minikube ya está ejecutándose"
else
  if command -v minikube &> /dev/null; then
    echo "🚀 Iniciando Minikube..."
    minikube start --driver=docker --memory=3072 --cpus=2 --disk-size=20g
  else
    echo "⚠️  Minikube no está instalado, saltando inicio"
  fi
fi

echo "📊 Estado de Minikube:"
if command -v minikube &> /dev/null; then
  minikube status
else
  echo "⚠️  Minikube no está instalado"
fi

echo "🔧 Configurando kubectl..."
if command -v minikube &> /dev/null; then
  minikube kubectl -- get nodes || true
else
  echo "⚠️  Minikube no está instalado, saltando configuración de kubectl"
fi

echo "🌐 Servicios disponibles:"
if command -v minikube &> /dev/null; then
  minikube service list || true
else
  echo "⚠️  Minikube no está instalado"
fi

echo "📋 Información del cluster:"
if command -v minikube &> /dev/null; then
  minikube kubectl -- get all || true
else
  echo "⚠️  Minikube no está instalado"
fi

echo "✅ Minikube configurado exitosamente"
EOF

echo "🎉 Configuración de Minikube completada en ${VM_IP}"
