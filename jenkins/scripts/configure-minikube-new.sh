#!/usr/bin/env bash
set -euo pipefail

# Script para configurar Minikube en la VM después de la creación
# Este script se ejecuta desde Jenkins para configurar Minikube específicamente

VM_IP="${1:-}"
if [[ -z "${VM_IP}" ]]; then
  echo "❌ Uso: $0 <VM_IP>" >&2
  exit 1
fi

echo "🚀 Configurando Minikube en VM ${VM_IP}..."

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

# Instalar y configurar Minikube paso a paso
echo "🚀 Instalando kubectl y Minikube (versión actualizada)..."
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${VM_IP}" << 'EOF'
set -euo pipefail

echo "📦 Paso 1: Verificando Docker..."
if ! command -v docker &> /dev/null; then
  echo "⚠️  Docker no está instalado, esperando a que cloud-init termine..."
  
  # Esperar a que cloud-init termine
  echo "⏳ Esperando a que cloud-init termine..."
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "   cloud-init aún ejecutándose, esperando..."
    sleep 10
  done
  echo "✅ cloud-init terminado, verificando Docker..."
  
  # Verificar si Docker se instaló correctamente
  if command -v docker &> /dev/null; then
    echo "✅ Docker instalado por cloud-init"
    docker --version
  else
    echo "❌ Error: Docker no se instaló correctamente en cloud-init"
    exit 1
  fi
else
  echo "✅ Docker ya está instalado"
  docker --version
fi

# Verificar permisos de Docker para el usuario jenkins
echo "🔍 Verificando permisos de Docker..."
if groups jenkins | grep -q docker; then
  echo "✅ Usuario jenkins tiene permisos de Docker"
else
  echo "⚠️  Agregando usuario jenkins al grupo docker..."
  sudo usermod -aG docker jenkins
  echo "✅ Usuario jenkins agregado al grupo docker"
fi

echo ""
echo "📦 Paso 2: Instalando kubectl..."
if ! command -v kubectl &> /dev/null; then
  echo "🔽 Descargando kubectl..."
  curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
  echo "📁 Instalando kubectl..."
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  echo "✅ kubectl instalado exitosamente"
  
  # Verificar instalación
  if command -v kubectl &> /dev/null; then
    echo "✅ Verificación: kubectl está disponible"
    kubectl version --client
  else
    echo "❌ Error: kubectl no está disponible después de la instalación"
    exit 1
  fi
else
  echo "✅ kubectl ya está instalado"
fi

echo ""
echo "📦 Paso 3: Instalando Minikube..."
if ! command -v minikube &> /dev/null; then
  echo "🔽 Descargando Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  echo "📁 Instalando Minikube..."
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
  echo "✅ Minikube instalado exitosamente"
  
  # Verificar instalación
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

echo ""
echo "🔧 Paso 4: Configurando Minikube..."
if command -v minikube &> /dev/null; then
  echo "⚙️  Configurando driver Docker..."
  minikube config set driver docker
  echo "⚙️  Configurando memoria (3GB)..."
  minikube config set memory 3072
  echo "⚙️  Configurando CPUs (2)..."
  minikube config set cpus 2
  echo "⚙️  Configurando disco (20GB)..."
  minikube config set disk-size 20g
  echo "✅ Configuración de Minikube completada"
else
  echo "⚠️  Minikube no está instalado, saltando configuración"
fi

echo ""
echo "🔍 Paso 5: Verificando estado de Minikube..."
if command -v minikube &> /dev/null && minikube status >/dev/null 2>&1; then
  echo "✅ Minikube ya está ejecutándose"
else
  if command -v minikube &> /dev/null; then
    echo "🚀 Iniciando Minikube..."
    minikube start --driver=docker --memory=3072 --cpus=2 --disk-size=20g
    echo "✅ Minikube iniciado exitosamente"
  else
    echo "⚠️  Minikube no está instalado, saltando inicio"
  fi
fi

echo ""
echo "📊 Paso 6: Mostrando estado final..."
if command -v minikube &> /dev/null; then
  echo "📊 Estado de Minikube:"
  minikube status
  
  echo ""
  echo "🔧 Configurando kubectl..."
  minikube kubectl -- get nodes || true
  
  echo ""
  echo "🌐 Servicios disponibles:"
  minikube service list || true
  
  echo ""
  echo "📋 Información del cluster:"
  minikube kubectl -- get all || true
else
  echo "⚠️  Minikube no está instalado"
fi

echo ""
echo "✅ Configuración de Minikube completada exitosamente"
EOF

echo "🎉 Configuración de Minikube completada en ${VM_IP}"
