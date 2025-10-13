# 🎭 Configuración del Ambiente Staging

## 📋 Índice
- [Introducción](#introducción)
- [¿Por qué Staging?](#por-qué-staging)
- [Arquitectura de Staging](#arquitectura-de-staging)
- [Configuración DOKS](#configuración-doks)
- [Configuración GKE](#configuración-gke)
- [Despliegue](#despliegue)
- [Validación](#validación)
- [Mejores Prácticas](#mejores-prácticas)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Introducción

El ambiente **staging** es un entorno de pre-producción diseñado para validar cambios antes de desplegarlos a producción. Es un paso crítico en el pipeline de CI/CD que ayuda a detectar problemas en un ambiente similar a producción.

### Características del Ambiente Staging

| Característica | Staging |
|---------------|---------|
| **Propósito** | Validación pre-producción |
| **Usuarios** | QA Team, Developers |
| **Datos** | Similares a producción (anonimizados) |
| **Configuración** | Intermedia entre dev y prod |
| **Uptime SLA** | 95% |
| **Costos** | Moderados |

---

## 🤔 ¿Por qué Staging?

### Ventajas de tener Staging

1. **Detección Temprana de Errores**
   - Pruebas en ambiente similar a producción
   - Validación de integraciones
   - Testing de performance

2. **Validación de Cambios de Infraestructura**
   - Probar upgrades de Kubernetes
   - Validar cambios de configuración
   - Testing de disaster recovery

3. **Pruebas de Integración**
   - APIs externas
   - Servicios de terceros
   - Flujos end-to-end

4. **Validación de QA**
   - Testing manual
   - Testing automatizado
   - User acceptance testing (UAT)

5. **Reducción de Riesgos**
   - Menos downtime en producción
   - Mayor confianza en deployments
   - Rollback más rápido si hay problemas

---

## 🏗️ Arquitectura de Staging

### Comparación entre Ambientes

| Componente | Dev | Staging | Prod |
|-----------|-----|---------|------|
| **Nodos (DOKS)** | 2 | 3 | 5 |
| **Tamaño Nodo (DOKS)** | s-2vcpu-4gb | s-2vcpu-4gb | s-4vcpu-8gb |
| **Auto-scaling (DOKS)** | 1-3 | 2-5 | 3-10 |
| **Nodos (GKE)** | 2 | 3 | 5 |
| **Tamaño Nodo (GKE)** | e2-medium | e2-standard-2 | e2-standard-4 |
| **Auto-scaling (GKE)** | 1-3 | 2-6 | 3-10 |
| **Tipo Cluster (GKE)** | Zonal | Regional | Regional + HA |
| **Aprobación Manual** | Opcional | ✅ Sí | ✅ Sí |
| **Monitoreo** | Básico | Completo | Completo + Alertas |
| **Backup** | No | Diario | Múltiples + PITR |

### Recursos de Staging

#### DOKS (DigitalOcean)
```
Cluster: ecommerce-staging-doks
Region: nyc1
Kubernetes Version: 1.28
Node Pool:
  - Name: general-pool
  - Size: s-2vcpu-4gb (2 vCPU, 4GB RAM)
  - Count: 3 nodos
  - Auto-scale: 2-5 nodos
```

#### GKE (Google Cloud)
```
Cluster: ecommerce-staging-gke
Region: us-central1
Type: Regional (multi-zone)
Kubernetes Version: 1.28
Node Pool:
  - Name: general-pool
  - Machine Type: e2-standard-2 (2 vCPU, 8GB RAM)
  - Count: 3 nodos
  - Auto-scale: 2-6 nodos
Network: Private cluster
```

---

## 🌊 Configuración DOKS

### 1. Preparar Variables

```bash
cd infra-ecommerce-microservice-backend-app/terraform/environments/staging/doks
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar terraform.tfvars

```hcl
# terraform.tfvars
cluster_name        = "ecommerce-staging-doks"
region              = "nyc1"
kubernetes_version  = "1.28"

# Opcional: cambiar región
# region = "sfo3"  # San Francisco
# region = "lon1"  # London
```

### 3. Configurar Credenciales

```bash
# Opción 1: Variable de ambiente
export TF_VAR_do_token="dop_v1_xxxxxxxxxxxxxxxxxxxx"

# Opción 2: En terraform.tfvars (NO COMMITEAR)
do_token = "dop_v1_xxxxxxxxxxxxxxxxxxxx"
```

### 4. Inicializar Terraform

```bash
cd terraform/environments/staging/doks
terraform init
```

### 5. Crear Plan

```bash
terraform plan -out=staging-plan.tfplan
```

### 6. Aplicar Cambios

```bash
# Revisar el plan primero
terraform show staging-plan.tfplan

# Aplicar
terraform apply staging-plan.tfplan
```

### 7. Obtener Kubeconfig

```bash
# Obtener cluster ID
CLUSTER_ID=$(terraform output -raw cluster_id)

# Descargar kubeconfig
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

---

## ☁️ Configuración GKE

### 1. Preparar Variables

```bash
cd infra-ecommerce-microservice-backend-app/terraform/environments/staging/gke
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar terraform.tfvars

```hcl
# terraform.tfvars
project_id          = "mi-proyecto-staging"
cluster_name        = "ecommerce-staging-gke"
region              = "us-central1"
kubernetes_version  = "1.28"

# Opcional: cambiar región
# region = "europe-west1"
# region = "asia-southeast1"
```

### 3. Configurar Credenciales

```bash
# Opción 1: Application Default Credentials
gcloud auth application-default login

# Opción 2: Service Account Key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# En terraform.tfvars (ruta al archivo)
credentials_file = "/path/to/service-account-key.json"
```

### 4. Inicializar Terraform

```bash
cd terraform/environments/staging/gke
terraform init
```

### 5. Crear Plan

```bash
terraform plan -out=staging-plan.tfplan
```

### 6. Aplicar Cambios

```bash
# Revisar el plan
terraform show staging-plan.tfplan

# Aplicar
terraform apply staging-plan.tfplan
```

### 7. Obtener Kubeconfig

```bash
# Obtener configuración del cluster
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw cluster_region)
PROJECT_ID=$(terraform output -raw project_id)

# Configurar kubectl
gcloud container clusters get-credentials $CLUSTER_NAME \
  --region=$REGION \
  --project=$PROJECT_ID

# Verificar
kubectl cluster-info
kubectl get nodes
```

---

## 🚀 Despliegue

### Usando Scripts de Automatización

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

### Usando Jenkins Pipeline

1. **Abrir Jenkins** → Crear nuevo Job → Pipeline

2. **Configurar Job:**
   - Name: `staging-cluster-deploy`
   - Type: Pipeline
   - Pipeline from SCM: Git

3. **Ejecutar Pipeline:**
   - Provider: `doks` o `gke`
   - Environment: `staging`
   - Action: `plan` → revisar → `apply`

4. **Aprobar Despliegue:**
   - Jenkins solicitará aprobación manual
   - Revisar el plan cuidadosamente
   - Aprobar para continuar

---

## ✅ Validación

### 1. Validar Cluster

```bash
# Usando script de validación
./jenkins/scripts/validate-cluster.sh

# Manual
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

### 2. Health Check

```bash
# Usando script
./jenkins/scripts/health-check.sh

# Manual
kubectl get componentstatuses
kubectl top nodes
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### 3. Verificar Configuración Base

```bash
# Namespaces
kubectl get namespaces

# Esperado:
# - ecommerce
# - monitoring
# - logging

# Ingress Controller
kubectl get pods -n ingress-nginx

# Cert-Manager
kubectl get pods -n cert-manager
```

### 4. Pruebas de Conectividad

```bash
# Desplegar pod de prueba
kubectl run test-pod --image=nginx --restart=Never

# Verificar
kubectl get pod test-pod
kubectl logs test-pod

# Limpiar
kubectl delete pod test-pod
```

### 5. Verificar Auto-scaling

```bash
# Ver configuración de auto-scaling
kubectl get hpa --all-namespaces

# DOKS
doctl kubernetes cluster get <cluster-id> --format ID,Name,Region,NodePools

# GKE
gcloud container node-pools describe general-pool \
  --cluster=ecommerce-staging-gke \
  --region=us-central1
```

---

## 💡 Mejores Prácticas

### 1. Gestión de Datos

```bash
# ❌ NO usar datos de producción reales
# ✅ Usar datos anonimizados o sintéticos

# Crear datos de prueba
kubectl apply -f kubernetes/seed-data/staging-data.yaml
```

### 2. Sincronización con Producción

```bash
# Mantener staging similar a prod

# Versiones de servicios
kubectl get deployments -n ecommerce -o yaml > staging-deployments.yaml

# Comparar con prod
diff staging-deployments.yaml prod-deployments.yaml
```

### 3. Testing Automatizado

```bash
# Ejecutar tests de integración
kubectl apply -f kubernetes/tests/integration-tests.yaml

# Verificar resultados
kubectl logs -n ecommerce -l job-name=integration-tests
```

### 4. Limpieza Regular

```bash
# Limpiar recursos antiguos (cada fin de semana)

# Eliminar pods completados
kubectl delete pods --field-selector=status.phase==Succeeded

# Limpiar jobs antiguos
kubectl delete jobs --field-selector=status.successful=1
```

### 5. Monitoreo

```bash
# Configurar alertas básicas (no tan estrictas como prod)

# Ver métricas
kubectl top nodes
kubectl top pods --all-namespaces

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Abrir http://localhost:9090
```

### 6. Backup y Restore

```bash
# Backup semanal de staging

# Backup de configuraciones
kubectl get all --all-namespaces -o yaml > staging-backup-$(date +%Y%m%d).yaml

# Backup de datos críticos
velero backup create staging-backup --include-namespaces ecommerce
```

---

## 🔧 Troubleshooting

### Problema: Nodos no se crean

#### DOKS
```bash
# Verificar status
doctl kubernetes cluster list

# Ver eventos
doctl kubernetes cluster kubeconfig show <cluster-id>

# Revisar límites de cuenta
doctl account ratelimit
```

#### GKE
```bash
# Verificar status
gcloud container clusters describe ecommerce-staging-gke \
  --region=us-central1

# Ver eventos
gcloud logging read "resource.type=k8s_cluster" --limit 50

# Verificar quotas
gcloud compute project-info describe --project=<project-id>
```

### Problema: Pods en estado Pending

```bash
# Ver eventos del pod
kubectl describe pod <pod-name> -n <namespace>

# Posibles causas:
# 1. Recursos insuficientes
kubectl top nodes

# 2. Taints/Tolerations
kubectl describe node <node-name>

# 3. Storage class no disponible
kubectl get sc
```

### Problema: Auto-scaling no funciona

```bash
# Verificar Metrics Server
kubectl get deployment metrics-server -n kube-system

# Ver logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Verificar HPA
kubectl get hpa --all-namespaces
kubectl describe hpa <hpa-name> -n <namespace>
```

### Problema: No puedo conectarme al cluster

#### DOKS
```bash
# Re-descargar kubeconfig
doctl kubernetes cluster kubeconfig save <cluster-id> --expiry-seconds 86400

# Verificar contexto
kubectl config current-context

# Cambiar contexto
kubectl config use-context do-<region>-<cluster-name>
```

#### GKE
```bash
# Re-autenticar
gcloud auth login
gcloud auth application-default login

# Re-descargar kubeconfig
gcloud container clusters get-credentials ecommerce-staging-gke \
  --region=us-central1

# Verificar permisos
gcloud projects get-iam-policy <project-id>
```

---

## 📊 Monitoreo de Costos

### Estimación de Costos Mensual

#### DOKS
```
3 nodos × s-2vcpu-4gb = 3 × $24/mes = $72/mes
Load Balancer = $12/mes
Total estimado: ~$84/mes
```

#### GKE
```
3 nodos × e2-standard-2 = 3 × $49/mes = $147/mes
Load Balancer = $20/mes
Total estimado: ~$167/mes

Nota: GKE cluster management: Gratis (hasta 1 cluster zonal)
      o $73/mes (regional)
```

### Optimización de Costos

```bash
# Apagar staging fuera de horario laboral
# Usar herramientas como:

# 1. Kube-downscaler
kubectl apply -f https://raw.githubusercontent.com/hjacobs/kube-downscaler/master/deploy/rbac.yaml

# 2. Configurar schedule
kubectl annotate deployment <deployment-name> \
  downscaler/uptime="Mon-Fri 08:00-18:00 America/New_York"

# 3. Escalar manualmente
kubectl scale deployment --replicas=0 --all -n ecommerce
```

---

## 🔄 Workflow Recomendado

### Ciclo de Vida de un Cambio

```
1. Desarrollar en DEV
   ↓
2. Commit y Push
   ↓
3. Jenkins deploy a STAGING automático
   ↓
4. QA Testing en STAGING
   ↓
5. Aprobación de QA
   ↓
6. Jenkins deploy a PROD con aprobación manual
   ↓
7. Verificación en PROD
```

### Comandos del Workflow

```bash
# 1. Desarrollar y probar en dev
git checkout -b feature/nueva-funcionalidad
# ... hacer cambios ...

# 2. Push a staging branch
git push origin feature/nueva-funcionalidad

# 3. Jenkins ejecuta automáticamente en staging
# (configurar webhook en Jenkins)

# 4. QA valida en staging
kubectl logs -f deployment/mi-servicio -n ecommerce

# 5. Si todo está OK, merge a main
git checkout main
git merge feature/nueva-funcionalidad
git push origin main

# 6. Jenkins deploy a prod (requiere aprobación)
# Revisar y aprobar en UI de Jenkins

# 7. Verificar en prod
kubectl rollout status deployment/mi-servicio -n ecommerce
```

---

## 📚 Referencias

- [DOKS Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform DOKS Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster)
- [Terraform GKE Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

## ❓ Preguntas Frecuentes

### ¿Cuándo usar staging vs dev?

- **Dev**: Desarrollo activo, cambios rápidos, pruebas individuales
- **Staging**: Pre-producción, QA completo, validación end-to-end

### ¿Staging debe tener los mismos datos que prod?

No. Usar datos similares pero anonimizados. Nunca datos reales de usuarios.

### ¿Puedo destruir y recrear staging?

Sí, es común destruir staging fuera de horario para ahorrar costos:

```bash
./terraform/scripts/destroy.sh doks staging
# Recrear cuando sea necesario
./terraform/scripts/apply.sh doks staging
```

### ¿Cuánto tiempo mantener staging activo?

Depende del presupuesto. Opciones:
- 24/7 para equipos distribuidos
- Solo horario laboral (8am-6pm)
- Solo cuando se necesite testing

---

## 🎉 Conclusión

El ambiente staging es crucial para un workflow de CI/CD robusto. Te permite:

- ✅ Detectar problemas antes de producción
- ✅ Validar cambios de infraestructura
- ✅ Realizar QA en ambiente realista
- ✅ Reducir riesgos en deployments
- ✅ Aumentar confianza en releases

**Próximo paso:** Configura tu ambiente staging y establece un workflow de testing robusto.
