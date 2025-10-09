#!/usr/bin/env bash
# Script de prueba local para crear infraestructura automáticamente
# Uso: export DO_TOKEN="tu_token" && ./scripts/test_local_infra.sh

set -euo pipefail

echo "🚀 Iniciando prueba de infraestructura automatizada..."
echo ""

# Verificar token DO
if [ -z "${DO_TOKEN:-}" ]; then
  echo "❌ Error: Define DO_TOKEN en environment"
  echo ""
  echo "Uso:"
  echo "  export DO_TOKEN='dop_v1_xxxxxxxxxxxxxxxxxxxxx'"
  echo "  ./scripts/test_local_infra.sh"
  echo ""
  exit 1
fi

# Crear directorio para SSH keys si no existe
mkdir -p .ssh

# Backup de terraform.tfvars si existe
if [ -f "terraform/dev/terraform.tfvars" ]; then
  echo "📦 Backup de terraform.tfvars existente..."
  cp terraform/dev/terraform.tfvars terraform/dev/terraform.tfvars.backup
fi

# Crear terraform.tfvars temporal
echo "✅ Creando configuración temporal..."
cat > terraform/dev/terraform.tfvars <<EOF
# Configuración generada automáticamente para pruebas
digitalocean_token = "$DO_TOKEN"
region              = "nyc1"
project_prefix      = "test-infra"

# Tamaños económicos para prueba
dev_size            = "s-1vcpu-1gb"
k8s_master_size     = "s-2vcpu-4gb"
k8s_worker_size     = "s-1vcpu-2gb"
k8s_worker_count    = 2

# Generar SSH key automáticamente
generate_ssh_key = true
EOF

cd terraform

echo ""
echo "✅ Inicializando Terraform..."
terraform init

echo ""
echo "✅ Validando configuración..."
terraform validate

echo ""
echo "✅ Planificando infraestructura..."
terraform plan -var-file=dev/terraform.tfvars

echo ""
read -p "¿Continuar con la creación? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Cancelado por el usuario"
  exit 0
fi

echo ""
echo "✅ Creando infraestructura..."
terraform apply -auto-approve -var-file=dev/terraform.tfvars

echo ""
echo "✅ Verificando outputs..."
terraform output

echo ""
echo "✅ Verificando inventario generado..."
if [ -f "../ansible/inventories/dev.ini" ]; then
  echo "📋 Contenido del inventario:"
  cat ../ansible/inventories/dev.ini
else
  echo "⚠️  Inventario no encontrado"
fi

echo ""
echo "✅ Verificando SSH key generada..."
if [ -f "../.ssh/terraform_rsa" ]; then
  echo "🔑 SSH private key: $(ls -lh ../.ssh/terraform_rsa)"
  echo "🔑 SSH public key: $(ls -lh ../.ssh/terraform_rsa.pub)"
else
  echo "⚠️  SSH key no encontrada"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🎉 Infraestructura creada exitosamente!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Recursos creados:"
echo "  • 1 VM Dev"
echo "  • 1 VM Stage Master"
echo "  • 2 VMs Stage Workers"
echo "  • SSH key generada automáticamente"
echo "  • Inventario Ansible generado"
echo ""
echo "🚀 Próximos pasos:"
echo "  1. cd ../ansible"
echo "  2. ansible-playbook -i inventories/dev.ini playbooks/setup-base.yml --limit all_dev_infra"
echo "  3. ansible-playbook -i inventories/dev.ini playbooks/setup-base.yml --limit all_stage_infra"
echo "  4. ansible-playbook -i inventories/dev.ini playbooks/setup-k8s.yml --limit all_stage_infra"
echo ""
echo "🗑️  Para destruir la infraestructura de prueba:"
echo "  terraform destroy -var-file=dev/terraform.tfvars"
echo ""
