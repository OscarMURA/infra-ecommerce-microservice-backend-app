#!/bin/bash
# Script de verificación rápida del setup
# Uso: ./scripts/verify_setup.sh

set -e

echo "🔍 Verificando configuración del proyecto..."
echo ""

# Verificar estructura de directorios
echo "✓ Verificando estructura de directorios..."
[ -d "terraform" ] || { echo "❌ Falta directorio terraform/"; exit 1; }
[ -d "ansible" ] || { echo "❌ Falta directorio ansible/"; exit 1; }
[ -d "scripts" ] || { echo "❌ Falta directorio scripts/"; exit 1; }
echo "  ✓ Directorios OK"
echo ""

# Verificar archivos clave
echo "✓ Verificando archivos clave..."
[ -f "terraform/main.tf" ] || { echo "❌ Falta terraform/main.tf"; exit 1; }
[ -f "terraform/variables.tf" ] || { echo "❌ Falta terraform/variables.tf"; exit 1; }
[ -f "terraform/outputs.tf" ] || { echo "❌ Falta terraform/outputs.tf"; exit 1; }
[ -f "scripts/generate_inventory_from_terraform.sh" ] || { echo "❌ Falta script de inventario"; exit 1; }
[ -f "Jenkinsfile" ] || { echo "❌ Falta Jenkinsfile"; exit 1; }
echo "  ✓ Archivos clave OK"
echo ""

# Verificar permisos de ejecución
echo "✓ Verificando permisos..."
[ -x "scripts/generate_inventory_from_terraform.sh" ] || { 
    echo "⚠️  Script de inventario no tiene permisos de ejecución"
    echo "   Ejecuta: chmod +x scripts/generate_inventory_from_terraform.sh"
}
echo "  ✓ Permisos OK"
echo ""

# Verificar herramientas necesarias
echo "✓ Verificando herramientas instaladas..."

if command -v terraform &> /dev/null; then
    echo "  ✓ Terraform: $(terraform version -json | jq -r '.terraform_version')"
else
    echo "  ❌ Terraform no instalado"
    echo "     Instala: https://www.terraform.io/downloads"
fi

if command -v ansible &> /dev/null; then
    echo "  ✓ Ansible: $(ansible --version | head -n1 | awk '{print $2}')"
else
    echo "  ❌ Ansible no instalado"
    echo "     Instala: sudo apt-get install -y ansible"
fi

if command -v jq &> /dev/null; then
    echo "  ✓ jq: $(jq --version)"
else
    echo "  ❌ jq no instalado (requerido para script de inventario)"
    echo "     Instala: sudo apt-get install -y jq"
fi

echo ""

# Verificar terraform.tfvars
echo "✓ Verificando configuración de Terraform..."
if [ -f "terraform/dev/terraform.tfvars" ]; then
    echo "  ✓ terraform/dev/terraform.tfvars existe"
    
    # Verificar que no tenga valores de ejemplo
    if grep -q "dop_v1_xxxx" terraform/dev/terraform.tfvars 2>/dev/null; then
        echo "  ⚠️  terraform.tfvars contiene valores de ejemplo"
        echo "     Edita el archivo con tus valores reales"
    fi
else
    echo "  ⚠️  terraform/dev/terraform.tfvars no existe"
    echo "     Copia desde: terraform/dev/terraform.tfvars.example"
    echo "     cp terraform/dev/terraform.tfvars.example terraform/dev/terraform.tfvars"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📋 Resumen de la configuración"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "VMs que se crearán:"
echo "  • 1 VM Dev (desarrollo)"
echo "  • 1 VM Stage Master (K8s control plane)"
echo "  • N VMs Stage Workers (por defecto: 2)"
echo ""
echo "Para escalar workers, edita terraform/dev/terraform.tfvars:"
echo "  k8s_worker_count = 3  # Incrementar a 3 workers"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🚀 Próximos pasos"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Edita terraform/dev/terraform.tfvars con tus valores"
echo "2. Ejecuta: cd terraform && terraform init"
echo "3. Ejecuta: terraform apply -var-file=dev/terraform.tfvars"
echo "4. Ejecuta: ../scripts/generate_inventory_from_terraform.sh"
echo "5. Verifica: cat ../ansible/inventories/dev.ini"
echo "6. Configura con Ansible o ejecuta pipeline en Jenkins"
echo ""
echo "✅ Verificación completada!"
