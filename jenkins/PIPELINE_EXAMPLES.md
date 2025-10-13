# Ejemplos de Pipeline de Jenkins

Este documento contiene ejemplos de cómo ejecutar el pipeline de Jenkins para diferentes escenarios.

## 📋 Tabla de Contenidos

- [Escenarios Comunes](#escenarios-comunes)
- [Parámetros del Pipeline](#parámetros-del-pipeline)
- [Ejemplos Paso a Paso](#ejemplos-paso-a-paso)
- [Troubleshooting](#troubleshooting)

---

## Escenarios Comunes

### 1. Desplegar cluster de desarrollo en DOKS

**Objetivo**: Crear un cluster de Kubernetes en DigitalOcean para desarrollo

**Parámetros**:
- PROVIDER: `doks`
- ENVIRONMENT: `dev`
- ACTION: `apply`
- AUTO_APPROVE: `true` (para dev)

**Resultado esperado**:
- Cluster con 2 nodos s-2vcpu-4gb
- Auto-scaling habilitado (1-3 nodos)
- VPC dedicada
- Firewall configurado

---

### 2. Desplegar cluster de producción en GKE

**Objetivo**: Crear un cluster regional de alta disponibilidad en Google Cloud

**Parámetros**:
- PROVIDER: `gke`
- ENVIRONMENT: `prod`
- ACTION: `apply`
- AUTO_APPROVE: `false` (requiere aprobación manual)

**Resultado esperado**:
- Cluster regional (3 zonas)
- Nodos e2-standard-4 con SSD
- Node pool crítico adicional
- Private nodes habilitados
- Binary authorization activo
- Managed Prometheus habilitado

---

### 3. Ver plan sin aplicar cambios (Preview)

**Objetivo**: Revisar qué cambios se harían sin aplicarlos

**Parámetros**:
- PROVIDER: `doks` o `gke`
- ENVIRONMENT: `dev` o `prod`
- ACTION: `plan`
- AUTO_APPROVE: N/A

**Resultado esperado**:
- Plan de Terraform generado
- Archivo `plan.txt` disponible en artefactos
- Sin cambios en infraestructura

---

### 4. Destruir infraestructura de desarrollo

**Objetivo**: Eliminar completamente el cluster de desarrollo

**Parámetros**:
- PROVIDER: `doks` o `gke`
- ENVIRONMENT: `dev`
- ACTION: `destroy`
- AUTO_APPROVE: N/A (siempre requiere aprobación)

**⚠️ ADVERTENCIA**: Esta acción elimina todos los recursos y NO se puede deshacer.

---

## Parámetros del Pipeline

### PROVIDER
Proveedor de nube a utilizar:
- `doks` - DigitalOcean Kubernetes Service
- `gke` - Google Kubernetes Engine

### ENVIRONMENT
Ambiente objetivo:
- `dev` - Desarrollo (costos menores, menos HA)
- `prod` - Producción (alta disponibilidad, más recursos)

### ACTION
Acción a ejecutar:
- `plan` - Ver cambios sin aplicar
- `apply` - Aplicar cambios (crear/actualizar)
- `destroy` - Destruir infraestructura

### AUTO_APPROVE
- `true` - Aplicar cambios automáticamente (solo recomendado para dev)
- `false` - Requiere aprobación manual antes de aplicar

---

## Ejemplos Paso a Paso

### Ejemplo 1: Primer despliegue en DOKS Dev

#### Paso 1: Plan
1. Ir a Jenkins
2. Seleccionar el job "Kubernetes Infrastructure Pipeline"
3. Click en "Build with Parameters"
4. Configurar:
   ```
   PROVIDER: doks
   ENVIRONMENT: dev
   ACTION: plan
   AUTO_APPROVE: false
   ```
5. Click en "Build"
6. Esperar a que termine
7. Descargar y revisar `plan.txt` en los artefactos

#### Paso 2: Apply
1. Click en "Build with Parameters" nuevamente
2. Configurar:
   ```
   PROVIDER: doks
   ENVIRONMENT: dev
   ACTION: apply
   AUTO_APPROVE: true
   ```
3. Click en "Build"
4. Esperar ~5-10 minutos
5. Revisar outputs en la consola

#### Paso 3: Verificar
```bash
# Configurar kubectl
doctl kubernetes cluster kubeconfig save ecommerce-dev-doks

# Verificar nodos
kubectl get nodes

# Ver información del cluster
kubectl cluster-info
```

---

### Ejemplo 2: Actualizar configuración de GKE Prod

#### Paso 1: Modificar configuración
Editar `terraform/environments/prod/gke/terraform.tfvars`:
```hcl
# Cambiar de 3 a 5 nodos mínimos
min_node_count = 5
```

Commit y push los cambios.

#### Paso 2: Revisar plan
1. En Jenkins, "Build with Parameters"
2. Configurar:
   ```
   PROVIDER: gke
   ENVIRONMENT: prod
   ACTION: plan
   AUTO_APPROVE: false
   ```
3. Revisar el plan generado cuidadosamente
4. Verificar que solo se modifique el min_node_count

#### Paso 3: Aprobar y aplicar
1. "Build with Parameters"
2. Configurar:
   ```
   PROVIDER: gke
   ENVIRONMENT: prod
   ACTION: apply
   AUTO_APPROVE: false
   ```
3. Click en "Build"
4. **ESPERAR LA APROBACIÓN MANUAL**
5. Revisar nuevamente el plan en la pausa
6. Click en "Aplicar cambios" para continuar
7. Monitorear los logs

#### Paso 4: Verificar
```bash
# Ver nodos
kubectl get nodes

# Verificar auto-scaling
kubectl get hpa -A

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' -A
```

---

### Ejemplo 3: Disaster Recovery - Recrear cluster

#### Escenario
El cluster de producción está corrupto y necesita recrearse.

#### Paso 1: Backup
```bash
# Backup de workloads
kubectl get all --all-namespaces -o yaml > backup-workloads.yaml

# Backup de configmaps y secrets
kubectl get configmaps,secrets --all-namespaces -o yaml > backup-configs.yaml
```

#### Paso 2: Destruir cluster corrupto
1. Jenkins "Build with Parameters"
2. Configurar:
   ```
   PROVIDER: gke
   ENVIRONMENT: prod
   ACTION: destroy
   AUTO_APPROVE: false
   ```
3. **CONFIRMAR** que tienes backups
4. Aprobar la destrucción

#### Paso 3: Recrear cluster
1. "Build with Parameters"
2. Configurar:
   ```
   PROVIDER: gke
   ENVIRONMENT: prod
   ACTION: apply
   AUTO_APPROVE: false
   ```
3. Aprobar después de revisar el plan
4. Esperar ~10-15 minutos

#### Paso 4: Restaurar workloads
```bash
# Configurar kubectl
gcloud container clusters get-credentials ecommerce-prod-gke --region us-central1

# Restaurar
kubectl apply -f backup-workloads.yaml
kubectl apply -f backup-configs.yaml
```

---

### Ejemplo 4: Pipeline desde Webhook (Automatizado)

#### Configuración inicial
1. En Jenkins, configurar webhook de GitHub/GitLab
2. Configurar branch filters (por ejemplo, solo `main`)

#### Flujo automático
1. Developer hace push a `main`:
   ```bash
   git add terraform/environments/dev/doks/terraform.tfvars
   git commit -m "Increase node count to 3"
   git push origin main
   ```

2. Jenkins detecta el webhook y ejecuta automáticamente:
   - ACTION: `plan`
   - Genera plan
   - Notifica al equipo (Slack, email)

3. DevOps revisa el plan y ejecuta manualmente:
   - ACTION: `apply`
   - Con aprobación requerida

---

## Logs y Outputs

### Ver logs en tiempo real
1. Click en el número de build
2. Click en "Console Output"
3. La página se actualiza automáticamente

### Descargar artefactos
Después de un build exitoso:
- `plan.txt` - Plan de Terraform en texto
- `outputs.json` - Outputs del módulo en JSON

### Ver outputs de Terraform
En la consola del build, al final verás:
```
📊 Outputs:
{
  "cluster_name": "ecommerce-dev-doks",
  "cluster_endpoint": "...",
  "kubeconfig_command": "doctl kubernetes cluster kubeconfig save ..."
}
```

---

## Troubleshooting

### Error: "terraform: command not found"
**Solución**: Instalar Terraform en el agente de Jenkins y agregarlo al PATH.

### Error: "Unable to authenticate"
**Solución**: Verificar credenciales en Jenkins:
- DOKS: Credential ID `digitalocean-token`
- GKE: Credential ID `gcp-service-account` y `gcp-project-id`

### Error: "Insufficient permissions"
**Solución**: 
- DOKS: Token debe tener permisos de escritura
- GKE: Service account necesita roles `container.admin` y `compute.admin`

### Build se queda "esperando aprobación"
**Normal**: Para producción, el pipeline espera aprobación manual.
**Acción**: 
1. Revisar el plan cuidadosamente
2. Click en "Aplicar cambios" para continuar
3. O "Abort" para cancelar

### Error: "Cluster creation failed"
**Verificar**:
- Cuotas no excedidas
- Región tiene capacidad
- Credenciales válidas
- Configuración correcta en terraform.tfvars

### Pipeline falla en "Health Check"
**Posibles causas**:
- Cluster aún se está inicializando (esperar)
- Nodos no están Ready
- CoreDNS no está desplegado

**Solución**:
```bash
# Verificar manualmente
kubectl get nodes
kubectl get pods -n kube-system
kubectl get events --sort-by='.lastTimestamp'
```

---

## Best Practices

1. **Siempre hacer plan primero** antes de apply
2. **Revisar los artefactos** generados
3. **Aprobar manualmente en prod** (AUTO_APPROVE=false)
4. **Documentar cambios** en commits descriptivos
5. **Notificar al equipo** antes de cambios en prod
6. **Tener plan de rollback** para prod
7. **Hacer backups** antes de cambios mayores
8. **Probar en dev** antes de aplicar en prod
9. **Monitorear durante y después** del despliegue
10. **Mantener logs** de todos los despliegues

---

## Plantilla de Comunicación

Para cambios en producción:

```
🚀 DESPLIEGUE EN PRODUCCIÓN

Fecha: [YYYY-MM-DD HH:MM]
Proveedor: [DOKS/GKE]
Ambiente: prod
Cambios: 
  - [Descripción del cambio 1]
  - [Descripción del cambio 2]

Ventana de mantenimiento: [HH:MM - HH:MM]
Impacto esperado: [Ninguno/Downtime breve/etc]
Rollback plan: [Descripción]

Pipeline: [URL del build en Jenkins]
Responsable: [Nombre]
Aprobado por: [Nombre]
```
