# Configuración de GKE (Google Kubernetes Engine)

## 📋 Prerequisitos

1. **Cuenta de Google Cloud**
   - Registrarse en [Google Cloud](https://cloud.google.com/)
   - Crear un proyecto
   - Habilitar facturación

2. **Herramientas requeridas**
   - Terraform >= 1.5.0
   - gcloud CLI
   - kubectl >= 1.27

## 🔑 Configuración Inicial

### 1. Instalar gcloud CLI

```bash
# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# macOS
brew install google-cloud-sdk

# Verificar instalación
gcloud version
```

### 2. Inicializar gcloud

```bash
# Autenticarse
gcloud auth login

# Listar proyectos
gcloud projects list

# Configurar proyecto por defecto
gcloud config set project YOUR_PROJECT_ID
```

### 3. Crear Service Account para Terraform

```bash
# Crear service account
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# Obtener email de la service account
SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:Terraform Service Account" \
    --format='value(email)')

echo $SA_EMAIL

# Asignar roles necesarios
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

# Crear y descargar key
gcloud iam service-accounts keys create ~/gcp-terraform-key.json \
    --iam-account=${SA_EMAIL}
```

### 4. Habilitar APIs necesarias

```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### 5. Configurar variables de Terraform

```bash
cd terraform/environments/dev/gke

# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tu configuración
nano terraform.tfvars
```

Contenido de `terraform.tfvars`:

```hcl
project_id       = "your-gcp-project-id"
credentials_file = "/home/user/gcp-terraform-key.json"

cluster_name       = "ecommerce-dev-gke"
region             = "us-central1"
zone               = "us-central1-a"
regional           = false  # true para cluster regional (más caro pero HA)

# Node Pool
machine_type   = "e2-medium"
disk_size_gb   = 50
node_count     = 2
min_node_count = 1
max_node_count = 4

# Network
subnet_cidr   = "10.0.0.0/20"
pods_cidr     = "10.4.0.0/14"
services_cidr = "10.8.0.0/20"

# Private Cluster
enable_private_nodes    = true
enable_private_endpoint = false  # true solo si accedes desde VPN

# Labels
labels = {
  "project"     = "ecommerce"
  "environment" = "dev"
}
```

## 🚀 Despliegue

### Opción 1: Scripts Automatizados

```bash
# Desde la raíz del proyecto
cd terraform

# Inicializar
./scripts/init.sh gke dev

# Ver plan
./scripts/plan.sh gke dev

# Aplicar
./scripts/apply.sh gke dev
```

### Opción 2: Comandos Terraform Directos

```bash
cd terraform/environments/dev/gke

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
# Obtener credenciales
gcloud container clusters get-credentials ecommerce-dev-gke \
    --region us-central1 \
    --project YOUR_PROJECT_ID

# Verificar contexto
kubectl config current-context

# Verificar nodos
kubectl get nodes

# Ver información del cluster
kubectl cluster-info
```

## 📊 Monitoreo

### Google Cloud Console

1. Ir a [GKE Console](https://console.cloud.google.com/kubernetes)
2. Seleccionar tu proyecto
3. Ver detalles del cluster

### Cloud Monitoring

```bash
# Ver métricas desde CLI
gcloud container clusters describe ecommerce-dev-gke \
    --region us-central1

# Ver uso de nodos
kubectl top nodes

# Ver uso de pods
kubectl top pods --all-namespaces
```

### Habilitar Managed Prometheus

```hcl
enable_managed_prometheus = true
```

## 💰 Costos Estimados

| Configuración | Costo Mensual (USD) |
|---------------|---------------------|
| Zonal, 2x e2-medium | ~$50-70 |
| Regional, 3x e2-medium | ~$150-200 |
| Zonal, 2x e2-standard-4 | ~$120-140 |

**Nota**: 
- Cluster zonal: control plane gratuito
- Cluster regional: $0.10/hora (~$73/mes) + nodos
- Verificar [GKE Pricing](https://cloud.google.com/kubernetes-engine/pricing)

## 🔧 Configuraciones Avanzadas

### Cluster Regional (Alta Disponibilidad)

```hcl
regional           = true
node_count_per_zone = 1  # Total = 1 x 3 zonas = 3 nodos
```

### Habilitar Autopilot Mode

Para clusters simplificados y más económicos:

```bash
# Crear cluster Autopilot (no compatible con módulo actual)
gcloud container clusters create-auto ecommerce-autopilot \
    --region us-central1 \
    --project YOUR_PROJECT_ID
```

### Workload Identity

Ya está habilitado en el módulo. Para usarlo:

```bash
# Crear service account de Kubernetes
kubectl create serviceaccount app-sa -n ecommerce

# Vincular con GCP service account
gcloud iam service-accounts add-iam-policy-binding \
    app-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:YOUR_PROJECT_ID.svc.id.goog[ecommerce/app-sa]"

# Anotar service account
kubectl annotate serviceaccount app-sa -n ecommerce \
    iam.gke.io/gcp-service-account=app-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Binary Authorization

Para mayor seguridad:

```hcl
enable_binary_authorization = true
```

## 🔒 Seguridad

### Private Cluster

```hcl
enable_private_nodes    = true
enable_private_endpoint = true  # Solo si tienes VPN/Cloud VPN
```

### Master Authorized Networks

Restringir acceso al control plane:

```hcl
master_authorized_networks = [
  {
    cidr_block   = "203.0.113.0/24"
    display_name = "office-network"
  },
  {
    cidr_block   = "198.51.100.0/24"
    display_name = "home-network"
  }
]
```

### Shielded Nodes

Ya está habilitado por defecto:

```hcl
enable_secure_boot          = true
enable_integrity_monitoring = true
```

## 🔄 Operaciones

### Escalar Node Pool

```bash
# Via gcloud
gcloud container clusters resize ecommerce-dev-gke \
    --node-pool default-pool \
    --num-nodes 3 \
    --region us-central1

# Via Terraform (editar terraform.tfvars)
node_count = 3
terraform apply
```

### Actualizar Kubernetes

```bash
# Ver versiones disponibles
gcloud container get-server-config --region us-central1

# Actualizar master
gcloud container clusters upgrade ecommerce-dev-gke \
    --master \
    --cluster-version 1.28.x-gke.x \
    --region us-central1

# Actualizar nodos
gcloud container clusters upgrade ecommerce-dev-gke \
    --node-pool default-pool \
    --region us-central1
```

## 🗑️ Limpieza

```bash
# Opción 1: Script
./scripts/destroy.sh gke dev

# Opción 2: Terraform
cd terraform/environments/dev/gke
terraform destroy

# Verificar eliminación
gcloud container clusters list
```

## 🐛 Troubleshooting

### Error: "API not enabled"

```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

### Error: "Insufficient permissions"

Verificar roles de service account:

```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:YOUR_SA_EMAIL"
```

### Nodos no pueden descargar imágenes

Verificar que los nodos tienen acceso a internet:

```bash
# Ver configuración de NAT
gcloud compute routers list

# Si es necesario, crear Cloud NAT
gcloud compute routers nats create nat-config \
    --router=nat-router \
    --region=us-central1 \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges
```

### Error de cuota

Solicitar aumento de cuota en [Quotas page](https://console.cloud.google.com/iam-admin/quotas)

## 📚 Referencias

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
