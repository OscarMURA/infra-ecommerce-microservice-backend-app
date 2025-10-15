# Azure Kubernetes Service (AKS) Setup Guide

Esta guía te ayudará a configurar Azure Kubernetes Service (AKS) con Jenkins y Terraform.

## 📋 Prerrequisitos

### 1. Azure CLI instalado y autenticado

```bash
# Instalar Azure CLI (si no lo tienes)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalación
az --version

# Iniciar sesión en Azure
az login

# Verificar tu cuenta
az account show

# Listar todas tus suscripciones
az account list --output table

# Establecer la suscripción por defecto (si tienes varias)
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Obtener información de tu cuenta de Azure

```bash
# Obtener Subscription ID
az account show --query id -o tsv

# Obtener Tenant ID
az account show --query tenantId -o tsv

# Guardar estos valores, los necesitarás para Jenkins
```

### 3. Verificar permisos

Tu cuenta de Azure debe tener los siguientes permisos:
- **Contributor** o **Owner** en la suscripción
- Permisos para crear recursos en Azure

```bash
# Verificar tu rol
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

## 🔧 Configuración Local

### 1. Configurar variables de Terraform

```bash
cd terraform/environments/dev/aks

# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

Actualiza los valores en `terraform.tfvars`:

```hcl
# Obtenlos con: az account show
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Configuración del cluster
cluster_name        = "ecommerce-aks-dev"
resource_group_name = "ecommerce-rg-dev"
location            = "eastus"  # o tu región preferida
dns_prefix          = "ecommerce-dev"

# Configuración de nodos (ajusta según tus necesidades)
node_size  = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
node_count = 2
min_nodes  = 1
max_nodes  = 3

# Tags
tags = {
  project     = "ecommerce"
  environment = "dev"
  managed-by  = "terraform"
}
```

### 2. Inicializar y aplicar Terraform localmente

```bash
# Inicializar Terraform
terraform init

# Ver el plan
terraform plan

# Aplicar (esto creará el cluster en Azure)
terraform apply

# Después de aplicar, obtener las credenciales
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --overwrite-existing

# Verificar conectividad
kubectl get nodes
kubectl cluster-info
```

## 🚀 Configuración de Jenkins

### 1. Instalar Azure CLI en Jenkins

Conéctate a tu servidor de Jenkins:

```bash
# Conectar por SSH
ssh jenkins@YOUR_JENKINS_SERVER

# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalación
az --version

# Instalar kubectl si no está instalado
sudo az aks install-cli
```

### 2. Configurar autenticación de Azure en Jenkins

Tienes dos opciones:

#### Opción A: Service Principal (Recomendado para Jenkins)

```bash
# Crear un Service Principal
az ad sp create-for-rbac --name jenkins-terraform-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Esto te dará un output similar a:
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "jenkins-terraform-sp",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

# Guardar estos valores, los necesitarás
```

Luego, en Jenkins, autenticar con el Service Principal:

```bash
# En el servidor de Jenkins
az login --service-principal \
  -u <appId> \
  -p <password> \
  --tenant <tenant>

# Verificar
az account show
```

#### Opción B: Usar tu cuenta personal (Solo para desarrollo/pruebas)

```bash
# En el servidor de Jenkins
az login --use-device-code

# Seguir las instrucciones en pantalla
# Verificar
az account show
```

### 3. Crear credenciales en Jenkins

1. Ve a **Jenkins > Manage Jenkins > Credentials**
2. Selecciona el dominio **(global)** o el específico de tu proyecto
3. Click en **Add Credentials**

**Credencial 1: Azure Subscription ID**
- Kind: **Secret text**
- Scope: **Global**
- Secret: `YOUR_SUBSCRIPTION_ID` (obtenlo con `az account show --query id -o tsv`)
- ID: `azure-subscription-id`
- Description: `Azure Subscription ID`

**Credencial 2: Azure Tenant ID**
- Kind: **Secret text**
- Scope: **Global**
- Secret: `YOUR_TENANT_ID` (obtenlo con `az account show --query tenantId -o tsv`)
- ID: `azure-tenant-id`
- Description: `Azure Tenant ID`

### 4. Verificar configuración en Jenkins

Crea un pipeline de prueba:

```groovy
pipeline {
    agent any
    stages {
        stage('Test Azure') {
            steps {
                script {
                    sh '''
                        echo "Verificando Azure CLI..."
                        az --version
                        echo ""
                        echo "Verificando autenticación..."
                        az account show
                    '''
                }
            }
        }
    }
}
```

## 📝 Usar el Pipeline de Jenkins

### 1. Crear el Job en Jenkins

1. Ve a **Jenkins Dashboard**
2. Click en **New Item**
3. Nombre: `Deploy-AKS-Infrastructure`
4. Tipo: **Pipeline**
5. En **Pipeline Definition**, selecciona **Pipeline script from SCM**
6. SCM: **Git**
7. Repository URL: Tu repositorio
8. Script Path: `jenkins/Jenkinsfile`

### 2. Ejecutar el Pipeline

1. Ve al job **Deploy-AKS-Infrastructure**
2. Click en **Build with Parameters**
3. Selecciona:
   - **PROVIDER**: `aks`
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `plan` (primero para ver los cambios)
4. Click en **Build**

### 3. Aplicar los cambios

Si el plan se ve bien:
1. Ejecuta de nuevo con **ACTION**: `apply`
2. El pipeline pedirá aprobación (excepto si marcas AUTO_APPROVE en dev)
3. Revisa los cambios y aprueba

## 🔍 Verificación

Después de aplicar, verifica que el cluster esté funcionando:

```bash
# Obtener credenciales
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev

# Verificar nodos
kubectl get nodes

# Verificar pods del sistema
kubectl get pods -n kube-system

# Ver información del cluster
az aks show \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --output table
```

## 🗑️ Limpiar recursos

Cuando termines las pruebas:

```bash
# Desde el pipeline de Jenkins con ACTION: destroy
# O localmente:
cd terraform/environments/dev/aks
terraform destroy
```

## 🌍 Regiones disponibles de Azure

Algunas regiones populares:
- `eastus` - East US (Virginia)
- `westus2` - West US 2 (Washington)
- `centralus` - Central US (Iowa)
- `westeurope` - West Europe (Netherlands)
- `northeurope` - North Europe (Ireland)
- `southeastasia` - Southeast Asia (Singapore)

Ver todas las regiones:
```bash
az account list-locations --output table
```

## 💰 Estimación de costos

Con la configuración por defecto (dev):
- **Standard_D2s_v3**: ~$96/mes por nodo
- **2 nodos**: ~$192/mes
- **Load Balancer**: ~$20/mes
- **Disco**: ~$10/mes

**Total aproximado**: ~$220/mes

Para reducir costos en desarrollo:
- Usa `Standard_B2s` (~$30/mes por nodo)
- Reduce a 1 nodo sin auto-scaling
- Apaga el cluster cuando no lo uses: `az aks stop --name CLUSTER_NAME --resource-group RG_NAME`

## 🆘 Troubleshooting

### Error: "az: command not found"
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Error: "You are not currently logged in"
```bash
az login
# o para service principal:
az login --service-principal -u APP_ID -p PASSWORD --tenant TENANT_ID
```

### Error: "Insufficient permissions"
Verifica que tengas rol de Contributor o Owner:
```bash
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### El cluster no aparece
```bash
# Verificar que el cluster existe
az aks list --output table

# Ver detalles del cluster
az aks show --name CLUSTER_NAME --resource-group RG_NAME
```

## 📚 Recursos adicionales

- [Documentación de AKS](https://docs.microsoft.com/azure/aks/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

## 🎯 Próximos pasos

1. ✅ Configurar Azure CLI y autenticación
2. ✅ Crear credenciales en Jenkins
3. ✅ Ejecutar el pipeline para crear el cluster
4. 📦 Desplegar tus microservicios en AKS
5. 🔒 Configurar seguridad y networking
6. 📊 Configurar monitoring con Azure Monitor
