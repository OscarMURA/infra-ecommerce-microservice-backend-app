# Configuración de DOKS (DigitalOcean Kubernetes Service)

## 📋 Prerequisitos

1. **Cuenta de DigitalOcean**
   - Registrarse en [DigitalOcean](https://www.digitalocean.com/)
   - Tener créditos o método de pago configurado

2. **Herramientas requeridas**
   - Terraform >= 1.5.0
   - doctl (DigitalOcean CLI)
   - kubectl >= 1.27

## 🔑 Configuración Inicial

### 1. Instalar doctl

```bash
# Linux
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.98.1/doctl-1.98.1-linux-amd64.tar.gz
tar xf doctl-1.98.1-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# macOS
brew install doctl

# Verificar instalación
doctl version
```

### 2. Crear Token de API

1. Ir a [DigitalOcean API Tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Generar nuevo token con permisos de lectura/escritura
3. Guardar el token de forma segura

### 3. Autenticar doctl

```bash
doctl auth init
# Ingresar el token cuando se solicite

# Verificar autenticación
doctl account get
```

### 4. Configurar variables de Terraform

```bash
cd terraform/environments/dev/doks

# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tu token
nano terraform.tfvars
```

Contenido de `terraform.tfvars`:

```hcl
do_token = "dop_v1_xxxxxxxxxxxxxxxxxxxxxx"

cluster_name = "ecommerce-dev-doks"
region       = "nyc1"  # o: sfo3, lon1, fra1, sgp1, etc.

# Node Pool
node_size  = "s-2vcpu-4gb"
node_count = 2
min_nodes  = 1
max_nodes  = 4

# Tags
tags = ["ecommerce", "microservices", "dev"]
```

## 🚀 Despliegue

### Opción 1: Scripts Automatizados

```bash
# Desde la raíz del proyecto
cd terraform

# Inicializar
./scripts/init.sh doks dev

# Ver plan
./scripts/plan.sh doks dev

# Aplicar
./scripts/apply.sh doks dev
```

### Opción 2: Comandos Terraform Directos

```bash
cd terraform/environments/dev/doks

# Inicializar
terraform init

# Plan
terraform plan

# Aplicar
terraform apply
```

## ⚙️ Configurar kubectl

Después de crear el cluster:

```bash
# Obtener kubeconfig
doctl kubernetes cluster kubeconfig save ecommerce-dev-doks

# Verificar contexto
kubectl config current-context

# Verificar nodos
kubectl get nodes

# Ver información del cluster
kubectl cluster-info
```

## 📊 Monitoreo

### Dashboard de DigitalOcean

1. Ir a [DigitalOcean Console](https://cloud.digitalocean.com/)
2. Navegar a "Kubernetes"
3. Seleccionar tu cluster

### Verificar estado con doctl

```bash
# Listar clusters
doctl kubernetes cluster list

# Ver detalles
doctl kubernetes cluster get ecommerce-dev-doks

# Listar node pools
doctl kubernetes cluster node-pool list ecommerce-dev-doks

# Ver nodos
doctl kubernetes cluster node-pool get ecommerce-dev-doks <node-pool-id>
```

## 💰 Costos Estimados

| Configuración | Costo Mensual (USD) |
|---------------|---------------------|
| 2x s-2vcpu-4gb | ~$48 |
| 3x s-2vcpu-4gb | ~$72 |
| 2x s-4vcpu-8gb | ~$96 |

**Nota**: Los precios pueden variar. Consultar [DigitalOcean Pricing](https://www.digitalocean.com/pricing/)

## 🔧 Configuraciones Avanzadas

### Habilitar Container Registry

```hcl
enable_container_registry = true
registry_name            = "ecommerce-registry"
registry_tier            = "basic"  # starter, basic, professional
```

Usar el registry:

```bash
# Autenticarse
doctl registry login

# Tag y push
docker tag myapp:latest registry.digitalocean.com/ecommerce-registry/myapp:latest
docker push registry.digitalocean.com/ecommerce-registry/myapp:latest
```

### Agregar Node Pool Adicional

```hcl
enable_critical_node_pool = true
critical_node_size       = "s-4vcpu-8gb"
critical_node_count      = 2
critical_min_nodes       = 1
critical_max_nodes       = 3
```

## 🔒 Seguridad

### Firewall Rules

El módulo crea automáticamente reglas de firewall. Para personalizar:

```hcl
firewall_inbound_rules = [
  {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  },
  {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }
]
```

### VPC Personalizada

```hcl
vpc_ip_range = "10.20.0.0/16"
```

## 🗑️ Limpieza

```bash
# Opción 1: Script
./scripts/destroy.sh doks dev

# Opción 2: Terraform
cd terraform/environments/dev/doks
terraform destroy

# Verificar que todo se eliminó
doctl kubernetes cluster list
```

## 🐛 Troubleshooting

### Error: "Unable to authenticate"

```bash
# Re-autenticar doctl
doctl auth init

# Verificar token
doctl auth list
```

### Error: "Cluster creation failed"

- Verificar que tienes créditos suficientes
- Verificar límites de tu cuenta en DigitalOcean
- Probar con otra región

### Nodos no están Ready

```bash
# Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Ver logs de nodos
kubectl describe node <node-name>

# Reiniciar node pool
doctl kubernetes cluster node-pool recycle ecommerce-dev-doks <pool-id>
```

## 📚 Referencias

- [DigitalOcean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [doctl CLI Reference](https://docs.digitalocean.com/reference/doctl/)
- [Terraform DigitalOcean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
