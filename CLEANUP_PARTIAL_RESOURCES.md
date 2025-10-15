# 🧹 Limpiar Recursos Parcialmente Creados

## ⚠️ Situación Actual

Terraform creó algunos recursos antes de fallar:
- ✅ Resource Group: `ecommerce-rg-dev`
- ✅ Virtual Network: `ecommerce-aks-dev-vnet`
- ✅ Subnet: `ecommerce-aks-dev-subnet`
- ✅ Log Analytics Workspace: `ecommerce-aks-dev-logs`
- ❌ AKS Cluster: **FALLÓ** (versión no soportada)

## 🔧 Solución

### Opción 1: Usar Jenkins para destruir (Recomendado)

1. Ve a Jenkins
2. Ejecuta el pipeline con:
   ```
   PROVIDER: aks
   ENVIRONMENT: dev
   ACTION: destroy
   ```
3. Espera que destruya todo (~5-10 minutos)
4. Luego ejecuta con `ACTION: apply` de nuevo

### Opción 2: Destruir manualmente con Azure CLI

```bash
# Eliminar todo el resource group (elimina todos los recursos dentro)
az group delete \
  --name ecommerce-rg-dev \
  --subscription 7ee4876b-15aa-495f-a236-7480ca6e7fdc \
  --yes --no-wait

# Verificar que se eliminó
az group show --name ecommerce-rg-dev
```

### Opción 3: Destruir desde el servidor de Jenkins

SSH al servidor de Jenkins y ejecuta:

```bash
# Ir al directorio de trabajo
cd /var/lib/jenkins/workspace/astructure-pipeline_infra_master/terraform/environments/dev/aks

# Destruir con Terraform
terraform destroy -auto-approve

# O si prefieres Azure CLI
az group delete --name ecommerce-rg-dev --yes --no-wait
```

## ✅ Después de destruir

1. Los recursos se limpiarán
2. Haz commit del fix de versión
3. Ejecuta el pipeline con `ACTION: apply`
4. Ahora debería funcionar con Kubernetes 1.31.11

## 📊 Verificar recursos actuales

```bash
# Ver todos los recursos en el resource group
az resource list \
  --resource-group ecommerce-rg-dev \
  --output table

# Ver el resource group
az group show \
  --name ecommerce-rg-dev \
  --output table
```

## 💰 Costo Actual

Los recursos creados hasta ahora tienen costo mínimo:
- Resource Group: Gratis
- VNet y Subnet: Gratis
- Log Analytics Workspace: ~$2-3/mes
- **Total**: < $5/mes mientras no haya AKS cluster

⚠️ **Importante**: Destruye o crea el cluster pronto para no dejar recursos huérfanos.
