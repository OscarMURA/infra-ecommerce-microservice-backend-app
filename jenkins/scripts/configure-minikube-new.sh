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

# Instalar todo desde cero
echo "🚀 Instalando Docker, kubectl y Minikube desde cero..."
sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${VM_IP}" << 'EOF'
set -euo pipefail

echo "📦 Paso 1: Instalando Docker..."
echo "🔽 Actualizando paquetes..."
sudo apt-get update

echo "🔽 Instalando dependencias..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "🔑 Configurando clave GPG de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "📦 Agregando repositorio de Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "🔄 Actualizando lista de paquetes..."
sudo apt-get update

echo "📦 Instalando paquetes de Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🚀 Iniciando servicio Docker..."
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins

echo "✅ Docker instalado exitosamente"
docker --version

echo ""
echo "📦 Paso 2: Instalando kubectl..."
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
echo "✅ kubectl instalado exitosamente"
kubectl version --client

echo ""
echo "📦 Paso 3: Instalando Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "✅ Minikube instalado exitosamente"
minikube version

echo ""
echo "🔧 Paso 4: Configurando Minikube..."
minikube config set driver docker
minikube config set memory 3072
minikube config set cpus 2
minikube config set disk-size 20g
echo "✅ Configuración de Minikube completada"

echo ""
echo "🔍 Paso 5: Iniciando Minikube..."
minikube start --driver=docker --memory=3072 --cpus=2 --disk-size=20g
echo "✅ Minikube iniciado exitosamente"

echo ""
echo "📊 Paso 6: Mostrando estado final..."
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

echo ""
echo "✅ Configuración de Minikube completada exitosamente"
EOF

echo "🎉 Configuración de Minikube completada en ${VM_IP}"