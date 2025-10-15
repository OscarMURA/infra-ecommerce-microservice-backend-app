# Infrastructure as Code - E-commerce Microservices

Este proyecto contiene la infraestructura como código (IaC) para desplegar el backend de microservicios de e-commerce en Kubernetes usando múltiples proveedores cloud.

## 🏗️ Estructura del Proyecto

```
infra-ecommerce-microservice-backend-app/
├── terraform/           # Configuración de Terraform
│   ├── modules/        # Módulos reutilizables (doks, gke, aks)
│   ├── environments/   # Configuraciones por ambiente (dev, staging, prod)
│   └── scripts/        # Scripts de automatización
├── jenkins/            # Pipelines de CI/CD
│   ├── Jenkinsfile    # Pipeline principal
│   └── scripts/       # Scripts de validación
├── kubernetes/         # Manifiestos de Kubernetes
└── docs/              # Documentación detallada
```

## 🚀 Proveedores Soportados

| Proveedor | Servicio | Estado |
|-----------|----------|--------|
| **DigitalOcean** | DOKS | ✅ Activo |
| **Google Cloud** | GKE | ✅ Activo |
| **Azure** | AKS | ✅ **NUEVO!** |

## 📋 Prerequisitos

- Terraform >= 1.5.0
- kubectl >= 1.27
- Jenkins >= 2.4
- Credenciales configuradas para al menos uno de:
  - **DigitalOcean**: Token de API
  - **Google Cloud**: Service Account JSON
  - **Azure**: Subscription ID y Tenant ID (az CLI configurado)

## 🎯 Inicio Rápido

### Para Azure (Nuevo!)

Si ya tienes Azure CLI configurado localmente, sigue esta guía:

```bash
# Ver guía rápida de Azure
cat AZURE_QUICK_START.md

# O ver el checklist
cat AZURE_CHECKLIST.md
```

**Documentación completa de Azure**: [`docs/aks-setup.md`](docs/aks-setup.md)

### Para DigitalOcean o Google Cloud

Consulta la documentación específica:
- DOKS: `docs/doks-setup.md`
- GKE: `docs/gke-setup.md`

## 🔧 Configuración Inicial

### 1. Configurar Variables de Entorno

```bash
# Para DOKS
export DO_TOKEN="your-digitalocean-token"

# Para GKE
export GOOGLE_CREDENTIALS="path/to/service-account.json"
export GOOGLE_PROJECT="your-gcp-project-id"

# Para AKS
az login
az account show  # Verificar autenticación
```

### 2. Inicializar Terraform

```bash
# Elegir proveedor y ambiente
cd terraform/environments/dev/aks  # o doks, o gke

# Configurar variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar con tus valores

# Inicializar y aplicar
terraform init
terraform plan
terraform apply
```

### 3. Configurar kubectl

```bash
# DOKS
doctl kubernetes cluster kubeconfig save <cluster-name>

# GKE
gcloud container clusters get-credentials <cluster-name> --region <region>
```

## 🔄 Jenkins Pipeline

Los pipelines de Jenkins automatizan:
- ✅ Validación de configuración de Terraform
- ✅ Creación de infraestructura
- ✅ Verificación de salud del cluster
- ✅ Despliegue de recursos de Kubernetes
- ✅ Tests de conectividad

Para ejecutar el pipeline:

1. Importa el `Jenkinsfile` en tu Jenkins
2. Configura las credenciales necesarias
3. Ejecuta el pipeline seleccionando el proveedor (DOKS/GKE)

## 📚 Documentación

- [Configuración DOKS](docs/doks-setup.md)
- [Configuración GKE](docs/gke-setup.md)
- [Configuración Staging](docs/staging-setup.md)
- [Configuración Jenkins](docs/jenkins-setup.md)

## 🌍 Ambientes

Este proyecto soporta tres ambientes:

| Ambiente | Propósito | Nodos | Aprobación |
|----------|-----------|-------|------------|
| **dev** | Desarrollo | 2 | Opcional |
| **staging** | Pre-producción/QA | 3 | ✅ Requerida |
| **prod** | Producción | 5 | ✅ Requerida |

## 🛡️ Seguridad

- Usa Terraform backend remoto (S3, GCS) para el estado
- Almacena secretos en gestores de secretos (Vault, Secret Manager)
- Aplica RBAC en los clusters de Kubernetes
- Escanea imágenes de Docker antes del despliegue

## 📝 Licencia

Este proyecto es parte del Taller 2 de Ingeniería de Software.
