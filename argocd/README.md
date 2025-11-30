# 🚀 ArgoCD - GitOps para E-commerce Microservices

## 📋 Descripción

**ArgoCD** es una herramienta de entrega continua declarativa para Kubernetes que sigue el patrón GitOps. Sincroniza automáticamente el estado del cluster con la configuración almacenada en Git.

## ✅ Requisitos del Taller Cumplidos

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| Implementar despliegue continuo con ArgoCD | ✅ | ArgoCD instalado + ApplicationSet |
| Configurar sincronización automática desde Git | ✅ | `syncPolicy.automated` habilitado |
| Implementar Progressive Delivery | ✅ | Canary deployment con Argo Rollouts |
| Configurar notificaciones de despliegue | ✅ | Slack + Webhook notifications |
| Implementar rollbacks automáticos basados en métricas | ✅ | AnalysisTemplate con Prometheus |

---

## 🏗️ Arquitectura GitOps

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GitOps Flow                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────┐         ┌──────────────┐         ┌──────────────┐       │
│   │  Developer   │         │    GitHub    │         │   ArgoCD     │       │
│   │              │ ──git──▶│              │◀──sync──│              │       │
│   │  Push Code   │  push   │  Repositories│         │  Controller  │       │
│   └──────────────┘         └──────────────┘         └──────┬───────┘       │
│                                                             │               │
│                                                             ▼               │
│                                                    ┌──────────────┐        │
│                                                    │  Kubernetes  │        │
│                                                    │   Cluster    │        │
│                                                    │              │        │
│   ┌──────────────────────────────────────────────▶│  ┌────────┐  │        │
│   │                                                │  │  prod  │  │        │
│   │  Notificaciones                                │  └────────┘  │        │
│   │  ┌──────────┐                                  │  ┌────────┐  │        │
│   │  │  Slack   │◀─────────────────────────────────│  │staging │  │        │
│   │  └──────────┘                                  │  └────────┘  │        │
│   │                                                └──────────────┘        │
│   │                                                                         │
└───┴─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Instalación

### 1. Instalar ArgoCD
```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer con LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### 2. Obtener credenciales
```bash
# Password inicial (usuario: admin)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Obtener IP externa
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### 3. Aplicar configuraciones
```bash
# Aplicar proyecto
kubectl apply -f argocd/project.yaml

# Aplicar ApplicationSet
kubectl apply -f argocd/applicationset.yaml

# Aplicar notificaciones
kubectl apply -f argocd/notifications.yaml
```

---

## 📁 Estructura de Archivos

```
argocd/
├── README.md                          # Esta documentación
├── project.yaml                       # AppProject - Agrupa todas las apps
├── applicationset.yaml                # ApplicationSet - Despliega todos los servicios
├── notifications.yaml                 # Configuración de notificaciones
├── apps/
│   └── order-service-canary.yaml      # App individual con Canary
└── rollouts/
    └── order-service-rollout.yaml     # Rollout con análisis de métricas
```

---

## 📊 Componentes Configurados

### 1️⃣ AppProject (project.yaml)

Define el proyecto que agrupa todas las aplicaciones:
- **Repositorios permitidos**: GitHub Ecommerce-Microservice-Lab
- **Namespaces destino**: prod, staging, dev
- **Roles**: developer (read-only), admin (full access)

### 2️⃣ ApplicationSet (applicationset.yaml)

Despliega automáticamente todos los microservicios:

| Servicio | Repositorio | Puerto |
|----------|-------------|--------|
| user-service | Ecommerce-Microservice-Lab/user-service | 8700 |
| product-service | Ecommerce-Microservice-Lab/product-service | 8500 |
| order-service | Ecommerce-Microservice-Lab/order-service | 8300 |
| payment-service | Ecommerce-Microservice-Lab/payment-service | 8400 |
| shipping-service | Ecommerce-Microservice-Lab/shipping-service | 8600 |
| favourite-service | Ecommerce-Microservice-Lab/favourite-service | 8800 |
| service-discovery | Ecommerce-Microservice-Lab/service-discovery | 8761 |
| api-gateway | Ecommerce-Microservice-Lab/api-gateway | 8080 |
| cloud-config | Ecommerce-Microservice-Lab/cloud-config | 9296 |

### 3️⃣ Sincronización Automática

```yaml
syncPolicy:
  automated:
    prune: true      # Elimina recursos que ya no están en Git
    selfHeal: true   # Auto-repara cambios manuales
```

### 4️⃣ Progressive Delivery (Canary)

Estrategia de despliegue gradual:
```
10% ──▶ pause 2m ──▶ análisis ──▶ 30% ──▶ pause 2m ──▶ 50% ──▶ análisis ──▶ 80% ──▶ 100%
```

### 5️⃣ Rollback Automático

Basado en métricas de Prometheus:
- **Success Rate**: >= 95%
- **Error Rate**: <= 5%
- **Latencia P99**: < 500ms

Si alguna métrica falla, ArgoCD hace rollback automático.

---

## 🔔 Notificaciones

### Eventos Configurados

| Evento | Notificación | Canal |
|--------|-------------|-------|
| Deployment exitoso | ✅ App deployed | #deployments |
| Sync fallido | ❌ Sync failed | #deployments |
| Health degradado | ⚠️ Health degraded | #alerts |
| Rollback ejecutado | 🔄 Rollback | #alerts |

### Ejemplo de mensaje Slack
```
✅ order-service desplegado exitosamente!
- Proyecto: ecommerce
- Revisión: abc1234
- Destino: prod
- Estado: Healthy
```

---

## 🧪 Verificación

### Ver estado de ArgoCD
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### Ver aplicaciones
```bash
# Listar todas las aplicaciones
kubectl get applications -n argocd

# Ver detalles de una aplicación
kubectl describe application order-service -n argocd

# Ver estado de sincronización
kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status"
```

### Acceder a la UI
```bash
# Obtener IP
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "ArgoCD UI: https://$ARGOCD_IP"

# Usuario: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 🔄 Flujo de Trabajo GitOps

### Despliegue Normal
```
1. Developer hace push a GitHub
2. ArgoCD detecta cambios (cada 3 min por defecto)
3. ArgoCD sincroniza automáticamente
4. Notificación de éxito/fallo
```

### Despliegue Canary
```
1. Push a branch main con nueva versión
2. ArgoCD inicia Canary (10% tráfico)
3. Análisis de métricas (2 min)
4. Si OK → incrementa a 30% → 50% → 80% → 100%
5. Si FALLA → Rollback automático
```

### Rollback Manual
```bash
# Via CLI
argocd app rollback order-service

# Via kubectl
kubectl argo rollouts undo order-service -n prod
```

---

## 📈 Métricas de Rollback

El sistema hace rollback automático si:

| Métrica | Condición de Fallo | Acción |
|---------|-------------------|--------|
| Success Rate | < 95% por 3 mediciones | Rollback |
| Error Rate | > 5% por 2 mediciones | Rollback |
| Latencia P99 | > 500ms por 3 mediciones | Rollback |

---

## 🔗 Referencias

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [ApplicationSet Controller](https://argocd-applicationset.readthedocs.io/)
- [ArgoCD Notifications](https://argocd-notifications.readthedocs.io/)

---

## 👥 Autores

- Equipo de DevOps - Taller 2 Ingeniería de Software
- Universidad Icesi - 2025
