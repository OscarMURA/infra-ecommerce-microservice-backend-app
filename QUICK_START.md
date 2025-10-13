# Guía Rápida de Uso

## 🚀 Quick Start

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd infra-ecommerce-microservice-backend-app
```

### 2. Elegir proveedor

**Para DigitalOcean (DOKS):**
```bash
cd terraform/environments/dev/doks
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tu token
```

**Para Google Cloud (GKE):**
```bash
cd terraform/environments/dev/gke
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tu project_id y credentials
```

### 3. Desplegar

```bash
# Volver a la raíz de terraform
cd ../../..

# Inicializar
./scripts/init.sh <provider> <environment>
# Ejemplo: ./scripts/init.sh doks dev

# Planificar
./scripts/plan.sh <provider> <environment>

# Aplicar
./scripts/apply.sh <provider> <environment>
```

### 4. Configurar kubectl

**DOKS:**
```bash
doctl kubernetes cluster kubeconfig save <cluster-name>
```

**GKE:**
```bash
gcloud container clusters get-credentials <cluster-name> --region <region>
```

### 5. Verificar

```bash
kubectl get nodes
kubectl cluster-info
```

## 📁 Estructura del Proyecto

```
infra-ecommerce-microservice-backend-app/
├── terraform/
│   ├── modules/              # Módulos reutilizables
│   │   ├── doks/            # Módulo DOKS
│   │   ├── gke/             # Módulo GKE
│   │   └── kubernetes-config/ # Configuración K8s
│   ├── environments/        # Configuraciones por ambiente
│   │   ├── dev/
│   │   │   ├── doks/
│   │   │   └── gke/
│   │   └── prod/
│   │       ├── doks/
│   │       └── gke/
│   └── scripts/             # Scripts de automatización
│       ├── init.sh
│       ├── plan.sh
│       ├── apply.sh
│       └── destroy.sh
├── jenkins/
│   ├── Jenkinsfile          # Pipeline principal
│   └── scripts/             # Scripts de validación
│       ├── validate-cluster.sh
│       └── health-check.sh
├── kubernetes/
│   └── manifests/           # Manifiestos base
│       ├── namespace.yaml
│       ├── configmap.yaml
│       └── secret.yaml
└── docs/                    # Documentación detallada
    ├── doks-setup.md
    ├── gke-setup.md
    └── jenkins-setup.md
```

## 🔑 Variables Importantes

### DOKS

```hcl
do_token           # Token de API de DigitalOcean
cluster_name       # Nombre del cluster
region             # Región (nyc1, sfo3, lon1, etc.)
node_size          # Tamaño de nodos (s-2vcpu-4gb, etc.)
node_count         # Número de nodos
```

### GKE

```hcl
project_id         # ID del proyecto GCP
credentials_file   # Archivo de service account
cluster_name       # Nombre del cluster
region             # Región (us-central1, etc.)
machine_type       # Tipo de máquina (e2-medium, etc.)
node_count         # Número de nodos
```

## 🎯 Comandos Comunes

### Terraform

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Formatear
terraform fmt -recursive

# Plan
terraform plan

# Aplicar
terraform apply

# Ver outputs
terraform output

# Destruir
terraform destroy
```

### kubectl

```bash
# Ver nodos
kubectl get nodes

# Ver pods
kubectl get pods -A

# Ver servicios
kubectl get svc -A

# Describir recurso
kubectl describe node <node-name>

# Ver logs
kubectl logs <pod-name> -n <namespace>

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
```

## 🔄 Workflow de Jenkins

1. **Plan**: Ver cambios sin aplicar
2. **Apply**: Aplicar cambios (requiere aprobación)
3. **Verify**: Validar que el cluster funciona
4. **Health Check**: Verificar salud del cluster

## 🗑️ Limpiar Recursos

```bash
# Con script
./scripts/destroy.sh <provider> <environment>

# Con terraform
cd terraform/environments/<env>/<provider>
terraform destroy
```

## ⚠️ Notas Importantes

1. **Nunca commitear** `terraform.tfvars` con secrets
2. **Usar backend remoto** para producción (S3, GCS)
3. **Aprobar manualmente** cambios en producción
4. **Hacer backup** del estado de Terraform
5. **Documentar** cambios importantes

## 📚 Documentación Completa

- [Configuración DOKS](docs/doks-setup.md)
- [Configuración GKE](docs/gke-setup.md)
- [Configuración Jenkins](docs/jenkins-setup.md)

## 🆘 Ayuda

Para problemas o preguntas:
1. Revisar la documentación en `docs/`
2. Verificar logs con `kubectl` o en la consola del proveedor
3. Ejecutar health checks con los scripts en `jenkins/scripts/`
