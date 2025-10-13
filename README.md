# Infrastructure as Code - E-commerce Microservices

Este proyecto contiene la infraestructura como código (IaC) para desplegar el backend de microservicios de e-commerce en Kubernetes.

## 🏗️ Estructura del Proyecto

```
infra-ecommerce-microservice-backend-app/
├── terraform/           # Configuración de Terraform
│   ├── modules/        # Módulos reutilizables
│   ├── environments/   # Configuraciones por ambiente
│   └── scripts/        # Scripts de automatización
├── jenkins/            # Pipelines de CI/CD
├── kubernetes/         # Manifiestos de Kubernetes
└── docs/              # Documentación
```

## 🚀 Proveedores Soportados

- **DOKS** (DigitalOcean Kubernetes Service)
- **GKE** (Google Kubernetes Engine)

## 📋 Prerequisitos

- Terraform >= 1.5.0
- kubectl >= 1.27
- Jenkins >= 2.4
- Credenciales configuradas para:
  - DigitalOcean (Token)
  - Google Cloud (Service Account)

## 🔧 Configuración Inicial

### 1. Configurar Variables de Entorno

```bash
# Para DOKS
export DO_TOKEN="your-digitalocean-token"

# Para GKE
export GOOGLE_CREDENTIALS="path/to/service-account.json"
export GOOGLE_PROJECT="your-gcp-project-id"
```

### 2. Inicializar Terraform

```bash
cd terraform/environments/dev/doks  # o gke
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
