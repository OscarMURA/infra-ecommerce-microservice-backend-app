# Solución al Error de Namespaces en GKE Dev

## Problema

El pipeline de Jenkins falló al intentar crear los namespaces `staging` y `prod` porque `gcloud` no estaba en el PATH cuando Terraform ejecutaba el provisioner `local-exec`.

```
Error: local-exec provisioner error
/bin/sh: 6: gcloud: not found
```

## Solución Implementada

He implementado una **solución de doble capa** para garantizar que los namespaces se creen correctamente:

### 1. Solución en Terraform (main.tf)

**Archivo modificado**: `terraform/environments/dev/gke/main.tf`

- Añadí la configuración del PATH en los `null_resource` para que encuentren `gcloud` y `kubectl`
- Agregué paths comunes donde suelen estar instalados estos comandos:
  - `/usr/local/bin`
  - `/usr/bin`
  - `/bin`
  - `/usr/local/google-cloud-sdk/bin`

```terraform
provisioner "local-exec" {
  command = <<-EOT
    # Configurar PATH para encontrar gcloud y kubectl
    export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/google-cloud-sdk/bin:$PATH
    
    gcloud container clusters get-credentials ...
  EOT
}
```

### 2. Solución de Respaldo en Health Check

**Archivo modificado**: `jenkins/scripts/health-check.sh`

- Añadí un paso que verifica y crea los namespaces automáticamente
- Solo se ejecuta en el ambiente `dev`
- Es idempotente: si los namespaces ya existen, solo los verifica

```bash
# 1.5. Crear/Verificar namespaces staging y prod (solo para dev)
if [ "$ENVIRONMENT" == "dev" ]; then
    # Crear namespace staging
    if kubectl get namespace staging &>/dev/null; then
        log_success "Namespace 'staging' ya existe"
    else
        kubectl create namespace staging
        kubectl label namespace staging environment=staging terraform=true app=ecommerce
        log_success "Namespace 'staging' creado"
    fi
    
    # Similar para prod...
fi
```

## Beneficios de esta Solución

1. **Doble garantía**: Si Terraform falla, el health check los creará
2. **Idempotente**: Puede ejecutarse múltiples veces sin problemas
3. **Labels correctos**: Los namespaces tienen los labels apropiados
4. **Visible en Jenkins**: Verás en el log si se crearon correctamente

## Cómo Probar la Solución

### Opción 1: Hacer commit y push de los cambios

```bash
cd /home/oscar/Documents/Taller\ 2\ Ingesoft/infra-ecommerce-microservice-backend-app

git add terraform/environments/dev/gke/main.tf
git add jenkins/scripts/health-check.sh
git commit -m "fix: añadir PATH a gcloud y crear namespaces en health-check"
git push origin infra/master
```

### Opción 2: Ejecutar el pipeline nuevamente

1. Ve a Jenkins
2. Selecciona el job `Infrastructure Pipeline`
3. Click en "Build with Parameters"
4. Selecciona:
   - **PROVIDER**: `gke`
   - **ENVIRONMENT**: `dev`
   - **ACTION**: `apply`
   - **AUTO_APPROVE**: `true` (si quieres evitar la aprobación manual)
5. Click en "Build"

### Opción 3: Aplicar manualmente los cambios (desde Jenkins o localmente)

Si ya tienes el cluster creado y solo quieres añadir los namespaces:

```bash
# Configurar kubectl para el cluster
gcloud container clusters get-credentials ecommerce-dev-gke-v2 \
  --zone us-central1-a \
  --project devops-activity

# Crear namespace staging
kubectl create namespace staging
kubectl label namespace staging environment=staging terraform=true app=ecommerce

# Crear namespace prod
kubectl create namespace prod
kubectl label namespace prod environment=production terraform=true app=ecommerce

# Verificar
kubectl get namespaces --show-labels
```

## Verificar que Todo Funciona

Después de ejecutar el pipeline, verifica que los namespaces se crearon:

```bash
# Listar todos los namespaces
kubectl get namespaces

# Ver los labels de los namespaces
kubectl get namespace staging -o yaml
kubectl get namespace prod -o yaml

# Debería mostrar algo como:
# NAME      STATUS   AGE
# default   Active   10m
# kube-system   Active   10m
# kube-public   Active   10m
# kube-node-lease   Active   10m
# staging   Active   5m
# prod      Active   5m
```

## Sobre el Problema del Nodo Único

También noté que tu cluster tiene solo 1 nodo. Esto es porque:

1. El autoscaling está habilitado con `min_node_count = 1`
2. Los valores por defecto en `variables.tf` permiten reducir a 1 nodo

Para asegurar mínimo 2 nodos, debes:

1. Modificar `terraform/environments/dev/gke/variables.tf` línea 139:
   ```terraform
   default     = 2  # Cambiar de 1 a 2
   ```

2. O crear un archivo `terraform.tfvars` con:
   ```terraform
   node_count     = 2
   min_node_count = 2
   max_node_count = 5
   ```

## Resumen de Cambios

- ✅ `terraform/environments/dev/gke/main.tf`: Añadido PATH a gcloud y kubectl
- ✅ `jenkins/scripts/health-check.sh`: Añadida creación automática de namespaces
- ✅ Solución de doble capa para máxima confiabilidad
- ℹ️  Pendiente: Ajustar `min_node_count` a 2 si quieres alta disponibilidad

## Próximos Pasos

1. Hacer commit de los cambios
2. Ejecutar el pipeline nuevamente
3. Verificar que los namespaces se crean correctamente
4. (Opcional) Ajustar el número mínimo de nodos a 2

