#!/bin/bash
# Script para instalar Google Cloud SDK en Jenkins

set -e

echo "📦 Instalando Google Cloud SDK en Jenkins..."

# Detectar el usuario actual
CURRENT_USER=$(whoami)
echo "Usuario actual: $CURRENT_USER"

# Configurar directorio de instalación
INSTALL_DIR="/opt/google-cloud-sdk"
GCLOUD_HOME="$INSTALL_DIR/google-cloud-sdk"

# Crear directorio de instalación si no existe
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Descargar e instalar gcloud
echo "⬇️ Descargando Google Cloud SDK..."
sudo curl -o google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz

echo "📂 Extrayendo archivos..."
sudo tar -xzf google-cloud-sdk.tar.gz

# Ejecutar el script de instalación sin interacción
echo "🔧 Instalando componentes..."
sudo "$GCLOUD_HOME/install.sh" \
  --usage-reporting=false \
  --path-update=false \
  --command-completion=false \
  --quiet

# Agregar gcloud al PATH global
echo "🔗 Configurando PATH..."
echo 'export PATH=/opt/google-cloud-sdk/google-cloud-sdk/bin:$PATH' | sudo tee /etc/profile.d/gcloud.sh
sudo chmod +x /etc/profile.d/gcloud.sh

# Configurar para el usuario jenkins
echo "👤 Configurando para usuario jenkins..."
sudo -u jenkins bash -c 'echo "export PATH=/opt/google-cloud-sdk/google-cloud-sdk/bin:\$PATH" >> /var/lib/jenkins/.bashrc'

# Dar permisos de ejecución
sudo chmod -R 755 "$GCLOUD_HOME"

# Verificar instalación
source /etc/profile.d/gcloud.sh
if command -v gcloud &> /dev/null; then
    echo "✅ Google Cloud SDK instalado exitosamente!"
    gcloud version
else
    echo "❌ Error: gcloud no está disponible"
    exit 1
fi

# Configurar gcloud para Jenkins
echo "⚙️ Configurando gcloud para Jenkins..."
sudo -u jenkins bash -c "export PATH=/opt/google-cloud-sdk/google-cloud-sdk/bin:\$PATH && gcloud config set core/disable_usage_reporting true && gcloud config set component_manager/disable_update_check true"

echo ""
echo "✨ Instalación completada!"
echo "📝 Para que Jenkins use gcloud, reinicia el servicio Jenkins:"
echo "   sudo systemctl restart jenkins"
echo ""
echo "🔍 Verifica que gcloud esté disponible ejecutando:"
echo "   sudo -u jenkins bash -c 'export PATH=/opt/google-cloud-sdk/google-cloud-sdk/bin:\$PATH && gcloud version'"
