# 🚀 Guía Rápida: Agregar Azure (AKS) a tu proyecto

## ✅ Ya tienes Azure CLI configurado localmente

Perfecto! Como ya tienes `az` configurado en tu máquina local, estos son los pasos para agregar AKS a tu infraestructura con Jenkins.

## 📋 Paso 1: Obtener información de tu cuenta de Azure

```bash
# 1. Obtener tu Subscription ID
az account show --query id -o tsv

# 2. Obtener tu Tenant ID
az account show --query tenantId -o tsv

# 3. Ver tu información completa
az account show
```

**Guarda estos valores**, los necesitarás en los siguientes pasos.

## 🔧 Paso 2: Configurar el ambiente local (dev)

```bash
# Navegar al directorio de AKS dev
cd terraform/environments/dev/aks

# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

Actualiza el archivo `terraform.tfvars` con tu información:

```hcl
# Pegar los valores que obtuviste en el Paso 1
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Tu subscription ID
tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Tu tenant ID

# Estos valores puedes dejarlos o personalizarlos
cluster_name        = "ecommerce-aks-dev"
resource_group_name = "ecommerce-rg-dev"
location            = "eastus"  # Cambia a tu región preferida
dns_prefix          = "ecommerce-dev"

# Configuración de nodos (ajusta según tu presupuesto)
node_size  = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM (~$96/mes por nodo)
node_count = 2
min_nodes  = 1
max_nodes  = 3
```

## 🧪 Paso 3: Probar localmente (Opcional pero recomendado)

```bash
# Inicializar Terraform
terraform init

# Ver el plan (sin aplicar cambios)
terraform plan

# Si todo se ve bien, aplicar
terraform apply

# Después de aplicar, obtener las credenciales del cluster
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --overwrite-existing

# Verificar que funciona
kubectl get nodes
kubectl cluster-info
```

## 🏗️ Paso 4: Configurar Jenkins

### 4.1. Instalar Azure CLI en Jenkins

Conéctate por SSH a tu servidor de Jenkins:

```bash
# Conectar a Jenkins
ssh jenkins@YOUR_JENKINS_SERVER

# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalación
az --version

# Instalar kubectl (si no está instalado)
sudo az aks install-cli
```

### 4.2. Autenticar Azure CLI en Jenkins

**Opción A: Service Principal (Recomendado para CI/CD)**

En tu máquina local:

```bash
# Crear un Service Principal para Jenkins
az ad sp create-for-rbac --name jenkins-terraform-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Output:
# {
#   "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "displayName": "jenkins-terraform-sp",
#   "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#   "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }

# Guardar estos valores
```

Luego, en el servidor de Jenkins:

```bash
# Autenticar con el Service Principal
az login --service-principal \
  -u <appId> \
  -p <password> \
  --tenant <tenant>

# Verificar
az account show
```

**Opción B: Usar tu cuenta personal (Solo para pruebas)**

En el servidor de Jenkins:

```bash
# Iniciar sesión
az login --use-device-code

# Seguir las instrucciones en pantalla
# Verificar
az account show
```

### 4.3. Configurar credenciales en Jenkins

1. Abre Jenkins en tu navegador: `http://YOUR_JENKINS_SERVER:8080`
2. Ve a **Manage Jenkins > Credentials**
3. Click en **(global)** o tu dominio
4. Click en **Add Credentials**

**Credencial 1:**
- Kind: **Secret text**
- Secret: `[Tu Subscription ID]`
- ID: `azure-subscription-id`
- Description: `Azure Subscription ID`
- Click **OK**

**Credencial 2:**
- Kind: **Secret text**
- Secret: `[Tu Tenant ID]`
- ID: `azure-tenant-id`
- Description: `Azure Tenant ID`
- Click **OK**

## ▶️ Paso 5: Ejecutar el Pipeline

### 5.1. El Pipeline ya está configurado

El archivo `jenkins/Jenkinsfile` ya tiene soporte para AKS. Solo necesitas ejecutarlo.

### 5.2. Crear/Actualizar el Job en Jenkins

Si ya tienes un Job de infraestructura:
1. Ve al Job
2. Click en **Configure**
3. Verifica que use el Jenkinsfile: `jenkins/Jenkinsfile`
4. **Save**

Si no tienes el Job:
1. Click en **New Item**
2. Nombre: `Deploy-Infrastructure`
3. Tipo: **Pipeline**
4. En **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `[URL de tu repo]`
   - Script Path: `jenkins/Jenkinsfile`
5. **Save**

### 5.3. Ejecutar

1. Ve al Job `Deploy-Infrastructure`
2. Click en **Build with Parameters**
3. Selecciona:
   - **PROVIDER**: `aks` ⬅️ **Aquí seleccionas Azure**
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `plan` (primero para ver)
   - **AUTO_APPROVE**: `false`
4. Click **Build**
5. Revisa el output del plan
6. Si todo está bien, ejecuta de nuevo con **ACTION**: `apply`
7. Aprueba cuando lo solicite

## ✅ Paso 6: Verificar

Después de que Jenkins aplique los cambios:

```bash
# En tu máquina local, obtener credenciales
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --overwrite-existing

# Verificar nodos
kubectl get nodes

# Ver pods del sistema
kubectl get pods -n kube-system

# Información del cluster
kubectl cluster-info
```

## 🎉 ¡Listo!

Ahora tienes tres opciones de proveedores en tu pipeline:
- **DOKS** (DigitalOcean Kubernetes)
- **GKE** (Google Kubernetes Engine)
- **AKS** (Azure Kubernetes Service) ⬅️ **Nuevo!**

## 📊 Comandos útiles de Azure

```bash
# Listar todos tus clusters AKS
az aks list --output table

# Ver detalles de un cluster
az aks show \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev

# Escalar el cluster
az aks scale \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --node-count 3

# Detener el cluster (para ahorrar costos)
az aks stop \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev

# Iniciar el cluster
az aks start \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev

# Ver costos estimados
az consumption usage list --output table
```

## 🗑️ Limpiar recursos

Para eliminar el cluster y todos los recursos:

```bash
# Desde Jenkins: ACTION = "destroy"
# O desde tu máquina local:
cd terraform/environments/dev/aks
terraform destroy
```

## 💡 Tips

1. **Costos**: AKS cobra por los VMs, no por el control plane. Con la config por defecto (~$220/mes)
2. **Regiones**: Usa `eastus` o `westus2` que suelen ser más baratas
3. **Desarrollo**: Para ahorrar, usa `Standard_B2s` en lugar de `Standard_D2s_v3`
4. **Detener**: Cuando no uses el cluster, detenlo con `az aks stop`

## 🆘 Problemas comunes

**"az: command not found" en Jenkins**
```bash
# En el servidor de Jenkins
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**"You are not currently logged in"**
```bash
# Verificar autenticación
az account show

# Si no está autenticado
az login
```

**"Insufficient permissions"**
```bash
# Verificar tu rol
az role assignment list --assignee $(az account show --query user.name -o tsv)
# Debes tener Contributor o Owner
```

## 📚 Más información

- [Guía completa de AKS](./docs/aks-setup.md)
- [Documentación de Azure](https://docs.microsoft.com/azure/aks/)
- [Calculadora de precios](https://azure.microsoft.com/pricing/calculator/)

---

**¿Necesitas ayuda?** Revisa los logs de Jenkins o ejecuta `terraform plan` localmente para ver qué está pasando.
