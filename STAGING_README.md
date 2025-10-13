# 🎭 Ambiente Staging - Resumen de Creación

## ✅ Archivos Creados

Se han creado exitosamente todos los archivos necesarios para el ambiente staging:

### Terraform DOKS Staging
```
terraform/environments/staging/doks/
├── main.tf                      ✅ Configuración del cluster DOKS staging
├── variables.tf                 ✅ Variables de entrada
├── outputs.tf                   ✅ Outputs del cluster
├── backend.tf                   ✅ Configuración de backend
└── terraform.tfvars.example     ✅ Ejemplo de variables
```

### Terraform GKE Staging
```
terraform/environments/staging/gke/
├── main.tf                      ✅ Configuración del cluster GKE staging
├── variables.tf                 ✅ Variables de entrada
├── outputs.tf                   ✅ Outputs del cluster
├── backend.tf                   ✅ Configuración de backend
└── terraform.tfvars.example     ✅ Ejemplo de variables
```

### Documentación
```
docs/
└── staging-setup.md             ✅ Guía completa de staging (600+ líneas)
```

### Actualizaciones
- ✅ `jenkins/Jenkinsfile` - Añadido staging a las opciones
- ✅ `PROJECT_SUMMARY.md` - Actualizado con información de staging
- ✅ `README.md` - Añadida tabla de ambientes

---

## 🎯 Configuración del Ambiente Staging

### Características Principales

| Aspecto | Staging (DOKS) | Staging (GKE) |
|---------|----------------|---------------|
| **Nodos** | 3 | 3 |
| **Tipo de Nodo** | s-2vcpu-4gb | e2-standard-2 |
| **vCPU por nodo** | 2 | 2 |
| **RAM por nodo** | 4 GB | 8 GB |
| **Auto-scaling** | 2-5 nodos | 2-6 nodos |
| **Región** | nyc1 | us-central1 |
| **Tipo Cluster** | - | Regional |
| **Costo Estimado** | ~$84/mes | ~$167/mes |

### Comparación con Otros Ambientes

| Característica | Dev | **Staging** | Prod |
|---------------|-----|-------------|------|
| Nodos | 2 | **3** | 5 |
| Auto-scaling min | 1 | **2** | 3 |
| Auto-scaling max | 3 | **5-6** | 10 |
| Aprobación manual | Opcional | **✅ Sí** | ✅ Sí |
| Propósito | Desarrollo | **QA/Testing** | Usuarios finales |
| Uptime SLA | - | **95%** | 99.9% |

---

## 🚀 Cómo Usar el Ambiente Staging

### Opción 1: Scripts de Terraform (Manual)

#### DOKS
```bash
cd infra-ecommerce-microservice-backend-app/terraform/environments/staging/doks

# 1. Copiar variables de ejemplo
cp terraform.tfvars.example terraform.tfvars

# 2. Editar terraform.tfvars
nano terraform.tfvars
# Configurar: do_token, cluster_name, region, kubernetes_version

# 3. Inicializar
terraform init

# 4. Planificar
terraform plan -out=staging.tfplan

# 5. Aplicar
terraform apply staging.tfplan

# 6. Obtener kubeconfig
CLUSTER_ID=$(terraform output -raw cluster_id)
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# 7. Verificar
kubectl get nodes
kubectl cluster-info
```

#### GKE
```bash
cd infra-ecommerce-microservice-backend-app/terraform/environments/staging/gke

# 1. Copiar variables de ejemplo
cp terraform.tfvars.example terraform.tfvars

# 2. Editar terraform.tfvars
nano terraform.tfvars
# Configurar: project_id, credentials_file, cluster_name, region

# 3. Autenticar con GCP
gcloud auth application-default login

# 4. Inicializar
terraform init

# 5. Planificar
terraform plan -out=staging.tfplan

# 6. Aplicar
terraform apply staging.tfplan

# 7. Obtener kubeconfig
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw cluster_region)
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION

# 8. Verificar
kubectl get nodes
kubectl cluster-info
```

### Opción 2: Scripts de Automatización

```bash
cd infra-ecommerce-microservice-backend-app

# DOKS
./terraform/scripts/init.sh doks staging
./terraform/scripts/plan.sh doks staging
./terraform/scripts/apply.sh doks staging

# GKE
./terraform/scripts/init.sh gke staging
./terraform/scripts/plan.sh gke staging
./terraform/scripts/apply.sh gke staging
```

### Opción 3: Jenkins Pipeline (Recomendado)

1. **Abrir Jenkins** → Ir al job de infraestructura

2. **Configurar parámetros:**
   - **PROVIDER**: Seleccionar `doks` o `gke`
   - **ENVIRONMENT**: Seleccionar `staging` 🎭
   - **ACTION**: Seleccionar `plan`
   - **AUTO_APPROVE**: Dejar en `false`

3. **Ejecutar plan:**
   - Click en "Build with Parameters"
   - Revisar el output del plan

4. **Aplicar cambios:**
   - Cambiar **ACTION** a `apply`
   - Ejecutar nuevamente
   - Jenkins pedirá aprobación manual
   - Revisar y aprobar

5. **Verificar:**
   - Jenkins ejecutará scripts de validación automáticamente
   - Revisar logs del pipeline
   - Conectar con kubectl y verificar

---

## 🔍 Validación Post-Despliegue

### 1. Verificar Nodos
```bash
kubectl get nodes

# Deberías ver 3 nodos en estado Ready
# NAME                   STATUS   ROLES    AGE   VERSION
# staging-pool-xxxxx-1   Ready    <none>   5m    v1.28.x
# staging-pool-xxxxx-2   Ready    <none>   5m    v1.28.x
# staging-pool-xxxxx-3   Ready    <none>   5m    v1.28.x
```

### 2. Verificar Componentes del Sistema
```bash
kubectl get pods --all-namespaces

# Verificar que todos los pods estén Running:
# - kube-system
# - ingress-nginx
# - cert-manager
# - ecommerce (si ya desplegaste la app)
```

### 3. Verificar Namespaces
```bash
kubectl get namespaces

# Deberías ver:
# - default
# - kube-system
# - ecommerce
# - monitoring
# - logging
```

### 4. Ejecutar Health Check
```bash
./jenkins/scripts/health-check.sh

# Este script verifica:
# ✅ Conectividad con el cluster
# ✅ Estado de los nodos
# ✅ Estado de los pods del sistema
# ✅ Disponibilidad de recursos
# ✅ Funcionalidad de auto-scaling
```

### 5. Prueba de Conectividad
```bash
# Desplegar pod de prueba
kubectl run test-nginx --image=nginx --restart=Never -n ecommerce

# Esperar a que esté listo
kubectl wait --for=condition=Ready pod/test-nginx -n ecommerce --timeout=60s

# Verificar logs
kubectl logs test-nginx -n ecommerce

# Limpiar
kubectl delete pod test-nginx -n ecommerce
```

---

## 💡 Flujo de Trabajo Recomendado

### Ciclo de Desarrollo con Staging

```
┌─────────────┐
│   Dev       │  1. Desarrollar y probar localmente
│   Local     │
└──────┬──────┘
       │
       ↓ git push
┌─────────────┐
│   Dev       │  2. Deploy automático a dev
│   Cluster   │     Testing individual
└──────┬──────┘
       │
       ↓ Merge a staging branch
┌─────────────┐
│  Staging    │  3. Deploy a staging
│  Cluster 🎭 │     - QA Testing
└──────┬──────┘     - Integration Testing
       │            - Performance Testing
       │            - Security Scanning
       │
       ↓ Aprobación de QA
┌─────────────┐
│  Producción │  4. Deploy a prod (con aprobación)
│  Cluster 🚀 │     Monitoreo intensivo
└─────────────┘
```

### Comandos del Workflow

```bash
# 1. Desarrollar en dev
git checkout -b feature/nueva-funcionalidad
# ... desarrollo ...
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/nueva-funcionalidad

# 2. Merge a staging (después de code review)
git checkout staging
git merge feature/nueva-funcionalidad

# 3. Trigger pipeline de Jenkins para staging
# O manual:
cd terraform/environments/staging/doks
terraform plan
terraform apply

# 4. QA realiza testing en staging
# Acceder a: https://staging.miapp.com

# 5. Si QA aprueba, merge a main
git checkout main
git merge staging
git push origin main

# 6. Deploy a producción (con aprobación en Jenkins)
```

---

## 🎨 Emojis del Pipeline

El Jenkinsfile ahora usa emojis específicos para cada ambiente:

- 🔧 **Dev** - Desarrollo (herramientas)
- 🎭 **Staging** - Teatro/Pruebas (máscaras de teatro)
- 🚀 **Prod** - Producción (cohete/lanzamiento)

Ejemplo en los logs de Jenkins:
```
🎭 Pipeline iniciado
Provider: doks
Environment: staging
Action: apply

🎭 STAGING - Revisar antes de aplicar
[Esperando aprobación manual...]

🎉 Pipeline completado exitosamente en STAGING
```

---

## 🧹 Mantenimiento

### Limpieza Regular

```bash
# Cada semana, limpiar recursos no utilizados
kubectl delete pods --field-selector=status.phase==Succeeded --all-namespaces
kubectl delete pods --field-selector=status.phase==Failed --all-namespaces

# Limpiar imágenes antiguas
kubectl delete pods --all-namespaces -l cleanup=true
```

### Actualización de Versión de Kubernetes

```bash
# 1. Actualizar en staging primero
cd terraform/environments/staging/doks
nano terraform.tfvars
# Cambiar: kubernetes_version = "1.29"

# 2. Aplicar actualización
terraform plan
terraform apply

# 3. Verificar que todo funciona
kubectl get nodes
./jenkins/scripts/health-check.sh

# 4. Si todo OK, actualizar prod
```

### Backup de Configuraciones

```bash
# Backup semanal
kubectl get all --all-namespaces -o yaml > staging-backup-$(date +%Y%m%d).yaml

# Backup de secrets (encriptados)
kubectl get secrets --all-namespaces -o yaml > staging-secrets-$(date +%Y%m%d).yaml
```

---

## 💰 Gestión de Costos

### Costos Mensuales Estimados

#### DOKS Staging
- 3 nodos s-2vcpu-4gb: 3 × $24 = **$72/mes**
- Load Balancer: **$12/mes**
- **Total: ~$84/mes**

#### GKE Staging
- 3 nodos e2-standard-2: 3 × $49 = **$147/mes**
- Load Balancer: **$20/mes**
- Cluster management fee (regional): **$73/mes**
- **Total: ~$240/mes**

### Estrategias de Ahorro

#### 1. Escalar a 0 fuera de horario
```bash
# Script para apagar staging (ej: fines de semana)
#!/bin/bash
# shutdown-staging.sh

kubectl scale deployment --replicas=0 --all -n ecommerce
kubectl scale statefulset --replicas=0 --all -n ecommerce

echo "✅ Staging scaled down"
```

#### 2. Usar Preemptible/Spot Instances (GKE)
```hcl
# En terraform/modules/gke/main.tf
node_pool {
  preemptible  = true  # Hasta 80% de descuento
  machine_type = "e2-standard-2"
}
```

#### 3. Destruir y recrear según necesidad
```bash
# Viernes por la noche
./terraform/scripts/destroy.sh doks staging

# Lunes por la mañana
./terraform/scripts/apply.sh doks staging
```

---

## 📞 Soporte

### Recursos Adicionales

- 📖 [Documentación Completa de Staging](docs/staging-setup.md)
- 📖 [DOKS Setup Guide](docs/doks-setup.md)
- 📖 [GKE Setup Guide](docs/gke-setup.md)
- 📖 [Jenkins Pipeline Guide](docs/jenkins-setup.md)

### Troubleshooting Común

Ver la sección de Troubleshooting en `docs/staging-setup.md` para:
- Problemas con creación de nodos
- Pods en estado Pending
- Auto-scaling no funciona
- Problemas de conectividad

---

## ✅ Checklist de Verificación

Usa este checklist después de crear staging:

- [ ] Cluster creado exitosamente
- [ ] 3 nodos en estado Ready
- [ ] Kubectl conectado y funcionando
- [ ] Namespaces creados (ecommerce, monitoring, logging)
- [ ] Ingress controller funcionando
- [ ] Cert-manager instalado
- [ ] Health check pasando
- [ ] Auto-scaling configurado
- [ ] Backup configurado
- [ ] Monitoreo básico funcionando
- [ ] Documentado en wiki del equipo
- [ ] Equipo de QA tiene acceso
- [ ] Pipelines de Jenkins configurados

---

## 🎉 ¡Listo!

Tu ambiente staging está completamente configurado y listo para usar. 

**Próximos pasos:**

1. ✅ Desplegar aplicación en staging
2. ✅ Configurar tests automatizados
3. ✅ Establecer proceso de QA
4. ✅ Documentar workflow para el equipo
5. ✅ Configurar alertas y monitoreo

Para cualquier duda, consulta la [documentación completa de staging](docs/staging-setup.md).

**¡Happy deploying! 🚀🎭**
