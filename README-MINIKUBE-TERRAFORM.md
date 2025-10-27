# VM Minikube con Terraform + Ansible

Esta configuración usa Terraform para crear la VM en DigitalOcean y Ansible para instalar y configurar Docker, kubectl y Minikube.

## 🚀 Uso Rápido

### 1. Configurar Variables

```bash
cd terraform/minikube-vm
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
```

### 2. Desplegar VM

```bash
# Desde el directorio raíz del proyecto
./deploy-minikube.sh create
```

### 3. Verificar Estado

```bash
./deploy-minikube.sh status
```

### 4. Destruir VM

```bash
./deploy-minikube.sh destroy
```

## 📋 Requisitos

- Terraform >= 1.0
- Ansible
- sshpass
- Token de DigitalOcean
- Password para el usuario jenkins

## 🔧 Configuración

### terraform.tfvars

```hcl
do_token   = "tu_token_de_digitalocean"
vm_name    = "ecommerce-minikube-dev"
region     = "nyc3"
size       = "s-2vcpu-4gb"
vm_password = "tu_password_seguro"
```

## 📊 Características de la VM

- **OS**: Ubuntu 22.04 LTS
- **RAM**: 4GB
- **CPU**: 2 vCPUs
- **Disco**: 77GB SSD
- **Región**: nyc3 (Nueva York)

## 🐳 Software Instalado

- Docker CE (última versión)
- kubectl v1.28.0
- Minikube (última versión)
- Configuración automática de Minikube

## 🔐 Acceso

```bash
ssh jenkins@VM_IP
# Password: el definido en terraform.tfvars
```

## 📁 Estructura

```
terraform/minikube-vm/
├── main.tf                    # Configuración de Terraform
└── terraform.tfvars.example  # Ejemplo de variables

ansible/minikube-vm/
├── playbook.yml              # Playbook de Ansible
└── inventory.ini             # Inventario (generado dinámicamente)

deploy-minikube.sh            # Script de despliegue principal
```

## 🎯 Ventajas de este Enfoque

1. **Sin conflictos de cloud-init**: Instalación controlada con Ansible
2. **Reproducible**: Misma configuración cada vez
3. **Escalable**: Fácil crear múltiples VMs
4. **Mantenible**: Código versionado y documentado
5. **Flexible**: Fácil modificar configuración

## 🔍 Troubleshooting

### Error de SSH
```bash
# Verificar que la VM esté ejecutándose
./deploy-minikube.sh status

# Verificar conectividad
ping VM_IP
```

### Error de Ansible
```bash
# Verificar inventario
cat ansible/minikube-vm/inventory.ini

# Ejecutar con verbose
ansible-playbook -i inventory.ini playbook.yml -vvv
```

### Error de Terraform
```bash
# Verificar variables
terraform validate

# Verificar plan
terraform plan
```

## 💰 Costos

- VM s-2vcpu-4gb: ~$24/mes
- Solo pagas por el tiempo que la VM esté ejecutándose
- Usa `destroy` cuando no la necesites
