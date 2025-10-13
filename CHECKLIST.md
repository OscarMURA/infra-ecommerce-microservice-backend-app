# ✅ Checklist de Verificación

## 📦 Pre-requisitos

### Herramientas Instaladas
- [ ] Terraform >= 1.5.0
- [ ] kubectl >= 1.27
- [ ] Git

### Para DOKS
- [ ] doctl CLI instalado
- [ ] Cuenta de DigitalOcean activa
- [ ] Token de API generado
- [ ] Créditos suficientes

### Para GKE
- [ ] gcloud CLI instalado
- [ ] Cuenta de Google Cloud activa
- [ ] Proyecto GCP creado
- [ ] Service Account con permisos creada
- [ ] APIs habilitadas (container.googleapis.com, compute.googleapis.com)
- [ ] Facturación habilitada

### Para Jenkins
- [ ] Jenkins instalado
- [ ] Plugins necesarios instalados
- [ ] Credenciales configuradas

---

## 🔧 Configuración Inicial

### DOKS
- [ ] doctl autenticado (`doctl auth init`)
- [ ] Token verificado (`doctl account get`)
- [ ] terraform.tfvars creado y configurado
- [ ] Variables sensibles NO commiteadas

### GKE
- [ ] gcloud autenticado (`gcloud auth login`)
- [ ] Proyecto configurado (`gcloud config set project`)
- [ ] Service Account key descargada
- [ ] terraform.tfvars creado y configurado
- [ ] Variables sensibles NO commiteadas

---

## 🚀 Despliegue

### Terraform
- [ ] Navegado al directorio correcto
- [ ] `terraform init` ejecutado exitosamente
- [ ] `terraform validate` sin errores
- [ ] `terraform fmt` aplicado
- [ ] `terraform plan` revisado
- [ ] Plan aprobado
- [ ] `terraform apply` ejecutado
- [ ] Outputs guardados

### kubectl
- [ ] kubeconfig configurado
- [ ] `kubectl get nodes` funciona
- [ ] `kubectl cluster-info` muestra información correcta
- [ ] Todos los nodos en estado Ready

---

## 📊 Verificación del Cluster

### Nodos
- [ ] Número correcto de nodos desplegados
- [ ] Todos los nodos en estado Ready
- [ ] Resources (CPU/Memory) adecuados

### Componentes del Sistema
- [ ] CoreDNS funcionando
- [ ] kube-proxy activo
- [ ] Metrics server (si aplica)

### Networking
- [ ] VPC/Network creada
- [ ] Subnets configuradas correctamente
- [ ] Firewall rules aplicadas
- [ ] Pods pueden comunicarse entre sí

### Storage
- [ ] Storage classes disponibles
- [ ] Persistent volumes funcionando (si aplica)

---

## 🔐 Seguridad

### Credenciales
- [ ] Secrets almacenados de forma segura
- [ ] Service accounts configuradas
- [ ] RBAC aplicado (si aplica)
- [ ] Tokens rotados regularmente

### Network
- [ ] Private nodes habilitados (producción)
- [ ] Master authorized networks configuradas (si aplica)
- [ ] Network policies aplicadas
- [ ] Firewall rules restrictivas

### Compliance
- [ ] Binary authorization (GKE prod)
- [ ] Secure boot habilitado
- [ ] Integrity monitoring activo
- [ ] Auditoría habilitada

---

## 📝 Kubernetes Resources

### Namespaces
- [ ] Namespace `ecommerce` creado
- [ ] Namespace `monitoring` creado (si aplica)
- [ ] Namespace `logging` creado (si aplica)

### ConfigMaps y Secrets
- [ ] ConfigMap `ecommerce-config` creado
- [ ] Secrets configurados
- [ ] Registry secrets (si aplica)

### Service Accounts
- [ ] Service account de aplicación creada
- [ ] Permisos asignados correctamente

---

## 🔄 Jenkins Pipeline

### Configuración
- [ ] Job creado en Jenkins
- [ ] Credenciales configuradas
- [ ] Pipeline conectado a repositorio
- [ ] Webhooks configurados (si aplica)

### Ejecución
- [ ] Pipeline ejecutado exitosamente
- [ ] Plan generado y revisado
- [ ] Apply completado sin errores
- [ ] Cluster verificado
- [ ] Health check pasado

---

## 📈 Monitoring y Logging

### DOKS
- [ ] DigitalOcean monitoring habilitado
- [ ] Alerts configuradas (si aplica)

### GKE
- [ ] Cloud Monitoring activo
- [ ] Cloud Logging habilitado
- [ ] Managed Prometheus (prod)
- [ ] Dashboards configurados

### General
- [ ] kubectl top nodes funciona
- [ ] Logs accesibles
- [ ] Métricas disponibles

---

## 🧪 Testing

### Conectividad
- [ ] Test pod puede crearse
- [ ] Pods pueden resolver DNS
- [ ] Pods pueden acceder a internet
- [ ] Services funcionan correctamente

### Aplicación (cuando se despliegue)
- [ ] Pods de aplicación corriendo
- [ ] Services expuestos correctamente
- [ ] Ingress funcionando (si aplica)
- [ ] Load balancer asignado

---

## 📚 Documentación

- [ ] README.md revisado
- [ ] QUICK_START.md probado
- [ ] Documentación específica del proveedor leída
- [ ] Scripts entendidos
- [ ] Outputs documentados

---

## 🔄 Post-Despliegue

### Backup
- [ ] Estado de Terraform respaldado
- [ ] Backend remoto configurado (prod)
- [ ] Snapshots de volúmenes (si aplica)

### Mantenimiento
- [ ] Ventana de mantenimiento configurada
- [ ] Plan de actualización definido
- [ ] Runbooks creados

### Disaster Recovery
- [ ] Plan de recuperación documentado
- [ ] Backups automatizados
- [ ] Procedimiento de restore probado

---

## ⚠️ Troubleshooting

### Problemas Comunes Verificados
- [ ] Credenciales válidas
- [ ] Permisos suficientes
- [ ] Cuotas no excedidas
- [ ] Recursos disponibles en región
- [ ] Versiones compatibles

---

## 🎯 Producción (Solo para Prod)

### Pre-Production
- [ ] Ambiente dev probado completamente
- [ ] Cambios revisados por equipo
- [ ] Aprobación formal obtenida
- [ ] Ventana de mantenimiento programada
- [ ] Rollback plan definido

### Durante Despliegue
- [ ] Comunicación a stakeholders
- [ ] Monitoreo activo
- [ ] Logs siendo observados
- [ ] Equipo en standby

### Post-Production
- [ ] Smoke tests ejecutados
- [ ] Métricas normales
- [ ] No hay errores críticos
- [ ] Usuarios notificados
- [ ] Documentación actualizada

---

## 📝 Notas

```
Fecha de despliegue: _________________
Desplegado por: _____________________
Proveedor: __________________________
Ambiente: ___________________________
Versión de Terraform: _______________
Versión de Kubernetes: ______________
Incidentes: _________________________
```

---

## 🚨 En Caso de Emergencia

### Rollback
```bash
# Revertir a estado anterior
cd terraform/environments/<env>/<provider>
terraform state pull > backup.tfstate
terraform destroy -target=<resource>
# o restaurar backup
```

### Soporte
- DOKS: https://docs.digitalocean.com/support/
- GKE: https://cloud.google.com/support
- Terraform: https://developer.hashicorp.com/terraform/docs

### Contactos
```
DevOps Lead: _______________________
Cloud Admin: _______________________
On-Call: ___________________________
```
