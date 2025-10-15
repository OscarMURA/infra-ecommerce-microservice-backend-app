# ✅ Checklist: Configuración de Azure (AKS) con Jenkins

## 📦 Archivos Creados

- ✅ Módulo Terraform AKS: `terraform/modules/aks/`
- ✅ Ambiente Dev: `terraform/environments/dev/aks/`
- ✅ Ambiente Staging: `terraform/environments/staging/aks/`
- ✅ Ambiente Prod: `terraform/environments/prod/aks/`
- ✅ Jenkinsfile actualizado con soporte para AKS
- ✅ Scripts de validación actualizados
- ✅ Documentación completa en `docs/aks-setup.md`

## 🎯 Pasos a Seguir

### [ ] 1. Configuración Local

```bash
cd terraform/environments/dev/aks
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Valores para pegar (ya los tienes en `AZURE_CREDENTIALS.md`):
```
subscription_id = "7ee4876b-15aa-495f-a236-7480ca6e7fdc"
tenant_id       = "e994072b-523e-4bfe-86e2-442c5e10b244"
```

### [ ] 2. Prueba Local (Opcional)

```bash
terraform init
terraform plan
# Si todo OK:
terraform apply
```

### [ ] 3. Configurar Jenkins Server

#### [ ] 3.1. Instalar Azure CLI en Jenkins

```bash
ssh jenkins@YOUR_JENKINS_IP
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version
sudo az aks install-cli
```

#### [ ] 3.2. Autenticar Azure en Jenkins

**Opción fácil (para pruebas):**
```bash
az login --use-device-code
az account show
```

**Opción recomendada (Service Principal):**

En tu PC local:
```bash
az ad sp create-for-rbac --name jenkins-terraform-sp \
  --role Contributor \
  --scopes /subscriptions/7ee4876b-15aa-495f-a236-7480ca6e7fdc
```

En Jenkins server:
```bash
az login --service-principal -u <appId> -p <password> --tenant <tenant>
```

### [ ] 4. Configurar Credenciales en Jenkins Web

1. Abrir: `http://JENKINS_IP:8080`
2. **Manage Jenkins** → **Credentials** → **(global)** → **Add Credentials**

#### [ ] Credencial 1: azure-subscription-id
```
Kind: Secret text
Secret: 7ee4876b-15aa-495f-a236-7480ca6e7fdc
ID: azure-subscription-id
```

#### [ ] Credencial 2: azure-tenant-id
```
Kind: Secret text
Secret: e994072b-523e-4bfe-86e2-442c5e10b244
ID: azure-tenant-id
```

### [ ] 5. Ejecutar Pipeline

1. Ve al Job de infraestructura
2. **Build with Parameters**
3. Selecciona:
   - **PROVIDER**: `aks`
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `plan`
4. Revisa output
5. Si OK, ejecuta con **ACTION**: `apply`

### [ ] 6. Verificar

```bash
az aks get-credentials \
  --resource-group ecommerce-rg-dev \
  --name ecommerce-aks-dev

kubectl get nodes
kubectl cluster-info
```

## 🎉 ¡Completado!

Ahora tienes 3 proveedores disponibles:
- DOKS (DigitalOcean)
- GKE (Google Cloud)
- AKS (Azure) ← **¡Nuevo!**

## 📚 Referencias Rápidas

| Documento | Propósito |
|-----------|-----------|
| `AZURE_QUICK_START.md` | Guía paso a paso completa |
| `AZURE_COMMANDS.md` | Comandos rápidos de referencia |
| `AZURE_CREDENTIALS.md` | Tus credenciales (NO SUBIR A GIT) |
| `docs/aks-setup.md` | Documentación detallada |

## 💰 Costos

**Configuración dev actual:**
- ~$220/mes (2 nodos Standard_D2s_v3)

**Para reducir costos:**
- Cambiar a `Standard_B2s`: ~$60/mes
- Detener cuando no uses: `az aks stop`
- Destruir después de pruebas: `terraform destroy`

## 🆘 ¿Problemas?

1. Verifica autenticación: `az account show`
2. Revisa logs de Jenkins
3. Consulta `AZURE_COMMANDS.md` para troubleshooting
4. Lee `docs/aks-setup.md` para más detalles

---

**Siguiente paso recomendado**: Ejecuta `terraform plan` localmente primero para ver qué se creará.
