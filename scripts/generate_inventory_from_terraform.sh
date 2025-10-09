#!/usr/bin/env bash
set -euo pipefail

# Script para generar ansible/inventories/dev.ini desde Terraform outputs
# Uso: ./scripts/generate_inventory_from_terraform.sh [terraform_dir] [output_inventory]

TF_DIR="${1:-terraform}"
OUT_INV="${2:-ansible/inventories/dev.ini}"

echo "==> Generando inventario Ansible desde Terraform outputs..."

# Verificar jq
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq no está instalado. Instala con: sudo apt-get install -y jq" >&2
  exit 1
fi

# Cambiar a directorio de Terraform
pushd "$TF_DIR" >/dev/null || exit 1

# Obtener outputs en JSON
echo "==> Obteniendo outputs de Terraform..."
TF_JSON=$(terraform output -json 2>/dev/null || echo '{}')

# Extraer IPs
mapfile -t DEV_IPS < <(echo "$TF_JSON" | jq -r '.dev_ips.value[]? // empty')
MASTER_IP=$(echo "$TF_JSON" | jq -r '.stage_master.value // empty')
mapfile -t WORKER_IPS < <(echo "$TF_JSON" | jq -r '.stage_workers.value[]? // empty')

popd >/dev/null

echo "==> Escribiendo inventario en $OUT_INV..."

# Crear directorio si no existe
mkdir -p "$(dirname "$OUT_INV")"

# Generar inventario
cat > "$OUT_INV" <<EOF
# Inventario generado automáticamente por scripts/generate_inventory_from_terraform.sh
# Generado el: $(date)

[dev_vms]
EOF

# Dev VMs
if [ ${#DEV_IPS[@]} -eq 0 ] || [ -z "${DEV_IPS[0]}" ]; then
  echo "# Ninguna VM Dev encontrada - agrega IPs manualmente" >> "$OUT_INV"
  echo "0.0.0.0 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
else
  for ip in "${DEV_IPS[@]}"; do
    [ -n "$ip" ] && echo "$ip ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
  done
fi

cat >> "$OUT_INV" <<EOF

[stage_k8s_master]
EOF

# Stage Master
if [ -z "$MASTER_IP" ]; then
  echo "# Ningún master encontrado - agrega IP manualmente" >> "$OUT_INV"
  echo "0.0.0.0 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
else
  echo "$MASTER_IP ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
fi

cat >> "$OUT_INV" <<EOF

[stage_k8s_workers]
EOF

# Stage Workers
if [ ${#WORKER_IPS[@]} -eq 0 ] || [ -z "${WORKER_IPS[0]}" ]; then
  echo "# Ningún worker encontrado - agrega IPs manualmente" >> "$OUT_INV"
  echo "0.0.0.0 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
else
  for ip in "${WORKER_IPS[@]}"; do
    [ -n "$ip" ] && echo "$ip ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> "$OUT_INV"
  done
fi

# Grupos adicionales
cat >> "$OUT_INV" <<'EOF'

[prod_vms]
# Agregar VMs de producción cuando sean necesarias
# 0.0.0.0 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

# Grupos para compatibilidad con playbooks existentes
[k8s_master:children]
stage_k8s_master

[k8s_workers:children]
stage_k8s_workers

# Grupos lógicos para despliegues por ambiente
[all_dev_infra:children]
dev_vms

[all_stage_infra:children]
stage_k8s_master
stage_k8s_workers

[all_prod_infra:children]
prod_vms
EOF

echo "==> Inventario generado exitosamente en: $OUT_INV"
echo ""
echo "Resumen:"
echo "  - Dev VMs: ${#DEV_IPS[@]}"
echo "  - Stage Master: $([ -n "$MASTER_IP" ] && echo "1" || echo "0")"
echo "  - Stage Workers: ${#WORKER_IPS[@]}"
echo ""

exit 0
