# 🎯 Comandos Rápidos - Configuración Azure + Jenkins

## 📍 1. En tu máquina local

### Obtener información de Azure
```bash
# Obtener Subscription ID y Tenant ID
az account show --query id -o tsv        # Copia este valor
az account show --query tenantId -o tsv  # Copia este valor
```

### Configurar Terraform
```bash
# Navegar al directorio
cd infra-ecommerce-microservice-backend-app/terraform/environments/dev/aks

# Crear archivo de configuración
cp terraform.tfvars.example terraform.tfvars

# Editar (pega los valores copiados arriba)
nano terraform.tfvars
```

### Probar localmente (Opcional)
```bash
terraform init
terraform plan
terraform apply  # Solo si quieres probar antes de Jenkins

# Si aplicaste, obtener credenciales
az aks get-credentials --resource-group ecommerce-rg-dev --name ecommerce-aks-dev
kubectl get nodes
```

---

## 🏗️ 2. En el servidor de Jenkins (SSH)

### Conectar a Jenkins
```bash
ssh jenkins@YOUR_JENKINS_IP
```

### Instalar Azure CLI
```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar
az --version

# Instalar kubectl (si no está)
sudo az aks install-cli
```

### Autenticar Azure

**OPCIÓN A - Service Principal (Recomendado):**

Primero en tu máquina local:
```bash
az ad sp create-for-rbac --name jenkins-terraform-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Guardar el output (appId, password, tenant)
```

Luego en Jenkins server:
```bash
az login --service-principal \
  -u <appId-del-output> \
  -p <password-del-output> \
  --tenant <tenant-del-output>

# Verificar
az account show
```

**OPCIÓN B - Tu cuenta (Solo para pruebas):**
```bash
az login --use-device-code
# Seguir las instrucciones en pantalla

# Verificar
az account show
```

---

## 🌐 3. En Jenkins Web UI

### Configurar Credenciales

1. Abrir: `http://YOUR_JENKINS_IP:8080`
2. **Manage Jenkins** → **Credentials** → **(global)** → **Add Credentials**

#### Credencial 1 - Subscription ID:
```
Kind: Secret text
Secret: [Pega tu Subscription ID]
ID: azure-subscription-id
Description: Azure Subscription ID
```

#### Credencial 2 - Tenant ID:
```
Kind: Secret text
Secret: [Pega tu Tenant ID]
ID: azure-tenant-id
Description: Azure Tenant ID
```

### Ejecutar el Pipeline

1. Ve al Job de infraestructura (o créalo apuntando a `jenkins/Jenkinsfile`)
2. **Build with Parameters**
3. Selecciona:
   ```
   PROVIDER: aks          ← Aquí seleccionas Azure
   ENVIRONMENT: dev
   ACTION: plan          ← Primero plan para ver
   AUTO_APPROVE: false
   ```
4. Click **Build**
5. Revisa el output
6. Si OK, ejecuta de nuevo con `ACTION: apply`

---

## ✅ 4. Verificar (En tu máquina local)

```bash
# Obtener credenciales del cluster
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev \
  --overwrite-existing

# Verificar nodos
kubectl get nodes

# Ver pods del sistema
kubectl get pods -n kube-system

# Info del cluster
kubectl cluster-info
```

---

## 🎉 ¡Eso es todo!

Ahora puedes usar AKS en tu pipeline igual que DOKS o GKE.

## 📝 Comandos útiles post-setup

```bash
# Ver todos tus clusters
az aks list --output table

# Detener cluster (ahorrar dinero)
az aks stop --name ecommerce-aks-dev --resource-group ecommerce-rg-dev

# Iniciar cluster
az aks start --name ecommerce-aks-dev --resource-group ecommerce-rg-dev

# Escalar
az aks scale --name ecommerce-aks-dev --resource-group ecommerce-rg-dev --node-count 3

# Eliminar todo
cd terraform/environments/dev/aks
terraform destroy
```

## 🆘 Troubleshooting rápido

| Problema | Solución |
|----------|----------|
| `az: command not found` | Instalar: `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| `not logged in` | Ejecutar: `az login` |
| `Insufficient permissions` | Verificar rol con: `az role assignment list` |
| Pipeline falla en Jenkins | Verificar: `az account show` en Jenkins server |
| No se conecta kubectl | Ejecutar: `az aks get-credentials --resource-group RG --name CLUSTER` |

---

## 💰 Costos estimados

**Configuración por defecto (dev):**
- 2 nodos Standard_D2s_v3: ~$192/mes
- Load Balancer: ~$20/mes
- **Total: ~$220/mes**

**Para ahorrar:**
- Usa `Standard_B2s` (~$60/mes para 2 nodos)
- Reduce a 1 nodo
- Detén cuando no uses: `az aks stop`
