#!/bin/bash
set -euo pipefail

# Script para desplegar VM de Minikube usando Terraform + Ansible
# Uso: ./deploy-minikube.sh [create|destroy|status]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform/minikube-vm"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible/minikube-vm"

ACTION="${1:-create}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

check_requirements() {
    log "Verificando requisitos..."
    
    if ! command -v terraform &> /dev/null; then
        error "Terraform no está instalado"
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        error "Ansible no está instalado"
    fi
    
    if ! command -v sshpass &> /dev/null; then
        error "sshpass no está instalado"
    fi
    
    success "Todos los requisitos están instalados"
}

check_tfvars() {
    if [[ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
        warning "terraform.tfvars no encontrado"
        log "Copiando ejemplo de terraform.tfvars.example..."
        cp "${TERRAFORM_DIR}/terraform.tfvars.example" "${TERRAFORM_DIR}/terraform.tfvars"
        error "Por favor edita terraform.tfvars con tus valores y ejecuta el script nuevamente"
    fi
}

deploy_vm() {
    log "Desplegando VM de Minikube con Terraform..."
    
    cd "${TERRAFORM_DIR}"
    
    log "Inicializando Terraform..."
    terraform init
    
    log "Planificando despliegue..."
    terraform plan
    
    log "Aplicando configuración..."
    terraform apply -auto-approve
    
    success "VM desplegada exitosamente"
}

wait_for_ssh() {
    local vm_ip="$1"
    local vm_password="$2"
    
    log "Esperando que SSH esté disponible en ${vm_ip}..."
    
    for i in {1..30}; do
        if sshpass -p "${vm_password}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jenkins@"${vm_ip}" "echo SSH ready" >/dev/null 2>&1; then
            success "SSH disponible en ${vm_ip}"
            return 0
        fi
        log "Reintentando conexión SSH ($i/30)..."
        sleep 10
    done
    
    error "No se pudo establecer conexión SSH con ${vm_ip}"
}

configure_with_ansible() {
    local vm_ip="$1"
    local vm_password="$2"
    
    log "Configurando VM con Ansible..."
    
    # Crear inventario dinámico
    cat > "${ANSIBLE_DIR}/inventory.ini" << EOF
[minikube_vm]
${vm_ip} ansible_user=jenkins ansible_password=${vm_password}
EOF
    
    # Configurar ansible.cfg para evitar warnings
    cat > "${ANSIBLE_DIR}/ansible.cfg" << EOF
[defaults]
host_key_checking = False
inventory = inventory.ini
remote_user = jenkins
private_key_file = 
ansible_ssh_pass = ${vm_password}

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF
    
    cd "${ANSIBLE_DIR}"
    
    log "Ejecutando playbook de Ansible..."
    ansible-playbook -i inventory.ini playbook.yml
    
    success "VM configurada exitosamente con Ansible"
}

get_vm_info() {
    cd "${TERRAFORM_DIR}"
    
    local vm_ip
    local vm_name
    local vm_id
    
    vm_ip=$(terraform output -raw droplet_ip)
    vm_name=$(terraform output -raw droplet_name)
    vm_id=$(terraform output -raw droplet_id)
    
    echo "VM_IP=${vm_ip}"
    echo "VM_NAME=${vm_name}"
    echo "VM_ID=${vm_id}"
}

destroy_vm() {
    log "Destruyendo VM de Minikube..."
    
    cd "${TERRAFORM_DIR}"
    
    log "Planificando destrucción..."
    terraform plan -destroy
    
    log "Destruyendo recursos..."
    terraform destroy -auto-approve
    
    success "VM destruida exitosamente"
}

show_status() {
    log "Mostrando estado de la VM..."
    
    cd "${TERRAFORM_DIR}"
    
    if terraform show >/dev/null 2>&1; then
        log "VM existe, mostrando información:"
        terraform show
        echo ""
        log "Outputs:"
        terraform output
    else
        warning "No hay VM desplegada"
    fi
}

main() {
    log "Iniciando despliegue de VM Minikube..."
    
    check_requirements
    
    case "${ACTION}" in
        "create")
            check_tfvars
            deploy_vm
            
            # Obtener información de la VM
            eval "$(get_vm_info)"
            
            # Obtener password del tfvars
            local vm_password
            vm_password=$(grep 'vm_password' "${TERRAFORM_DIR}/terraform.tfvars" | cut -d'"' -f2)
            
            wait_for_ssh "${VM_IP}" "${vm_password}"
            configure_with_ansible "${VM_IP}" "${vm_password}"
            
            success "Despliegue completo exitoso!"
            log "VM IP: ${VM_IP}"
            log "SSH: ssh jenkins@${VM_IP}"
            log "Password: ${vm_password}"
            ;;
        "destroy")
            destroy_vm
            ;;
        "status")
            show_status
            ;;
        *)
            error "Acción no válida: ${ACTION}. Use: create, destroy, o status"
            ;;
    esac
}

main "$@"
