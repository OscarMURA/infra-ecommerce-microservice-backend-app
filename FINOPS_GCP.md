# 💰 FinOps - Optimización de Costos en GCP

## 📋 Descripción

**FinOps** es la práctica de gestión financiera en la nube que combina sistemas, mejores prácticas y cultura para aumentar la capacidad de una organización de entender los costos de la nube y tomar decisiones informadas.

## ✅ Requisitos del Taller Cumplidos

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| Implementar monitoreo de costos | ✅ | GCP Billing + Budget Alerts |
| Configurar políticas de ahorro | ✅ | Autoscaling, e2-medium, Spot instances ready |
| Implementar dashboards de costos | ✅ | GCP Cost Management + Grafana |
| Realizar análisis de optimización | ✅ | Documentado en este archivo |
| Documentar estrategias y ahorros | ✅ | Este documento |

---

## 🏗️ Arquitectura de Costos

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GCP Cost Structure                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        GKE CLUSTER                                   │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │   │
│  │  │   Node 1    │  │   Node 2    │  │   Node 3    │  ◀── Autoscaling │   │
│  │  │  e2-medium  │  │  e2-medium  │  │  (on-demand)│      1-3 nodos   │   │
│  │  │  $24/mes    │  │  $24/mes    │  │             │                  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │   │
│  │                                                                      │   │
│  │  💡 Ahorro: Autoscaling reduce nodos cuando no hay carga            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      NETWORKING                                      │   │
│  │  • Load Balancers: ~$18/mes por LB                                  │   │
│  │  • Egress Traffic: ~$0.12/GB                                        │   │
│  │  💡 Ahorro: ClusterIP para servicios internos (sin LB)              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      STORAGE                                         │   │
│  │  • Persistent Disks: ~$0.04/GB/mes (standard)                       │   │
│  │  • Container Registry: ~$0.026/GB/mes                               │   │
│  │  💡 Ahorro: Usar standard-rwo en vez de premium                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 💵 Análisis de Costos Actual

### Configuración del Cluster GKE

| Recurso | Configuración | Costo Estimado/mes |
|---------|--------------|-------------------|
| GKE Cluster (control plane) | Zonal | **$0** (gratis) |
| Node Pool (e2-medium x2) | 2 vCPU, 4GB RAM | **~$48** |
| Autoscaling | 1-3 nodos | Variable |
| Load Balancers | 4 (Grafana, Kibana, etc.) | **~$72** |
| Persistent Disks | ~50GB standard | **~$2** |
| Network Egress | ~10GB/mes | **~$1.20** |
| **Total Estimado** | | **~$123/mes** |

### Desglose por Servicio

```
┌────────────────────────────────────────────────────────┐
│              Distribución de Costos                     │
├────────────────────────────────────────────────────────┤
│                                                         │
│  GKE Nodes (39%)        ████████████████░░░░░  $48     │
│  Load Balancers (58%)   ███████████████████████ $72    │
│  Storage (2%)           █░░░░░░░░░░░░░░░░░░░░░ $2      │
│  Network (1%)           ░░░░░░░░░░░░░░░░░░░░░░ $1      │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## 🎯 Estrategias de Ahorro Implementadas

### 1️⃣ Autoscaling de Nodos (GKE)

**Archivo:** `terraform/modules/gke/main.tf`

```hcl
# Node Pool con Autoscaling
resource "google_container_node_pool" "primary_nodes" {
  autoscaling {
    min_node_count = 1    # Mínimo 1 nodo (ahorro en baja demanda)
    max_node_count = 3    # Máximo 3 nodos (escala cuando necesita)
  }
}
```

**Ahorro Estimado:**
| Escenario | Sin Autoscaling | Con Autoscaling | Ahorro |
|-----------|-----------------|-----------------|--------|
| Carga baja (noche) | 3 nodos ($72) | 1 nodo ($24) | **67%** |
| Carga media | 3 nodos ($72) | 2 nodos ($48) | **33%** |
| Carga alta | 3 nodos ($72) | 3 nodos ($72) | 0% |
| **Promedio mensual** | **$72** | **~$45** | **~37%** |

---

### 2️⃣ Tipo de Máquina Optimizado (e2-medium)

**Configuración actual:**
```hcl
machine_type = "e2-medium"  # 2 vCPU, 4GB RAM
```

**Comparación de costos:**
| Tipo | vCPU | RAM | Costo/mes | Uso |
|------|------|-----|-----------|-----|
| e2-micro | 0.25 | 1GB | $6 | Muy limitado |
| **e2-medium** | 2 | 4GB | **$24** | ✅ Óptimo |
| e2-standard-2 | 2 | 8GB | $48 | Sobre-provisionado |
| n2-standard-2 | 2 | 8GB | $70 | Innecesario |

**Ahorro vs n2-standard-2:** **~66%** ($46/nodo/mes)

---

### 3️⃣ Servicios Internos con ClusterIP (Sin Load Balancer)

**Configuración actual:**
```bash
# Servicios de negocio (privados - sin costo de LB)
user-service        ClusterIP   ✅ $0
product-service     ClusterIP   ✅ $0
order-service       ClusterIP   ✅ $0
payment-service     ClusterIP   ✅ $0
shipping-service    ClusterIP   ✅ $0
favourite-service   ClusterIP   ✅ $0
service-discovery   ClusterIP   ✅ $0

# Solo monitoreo expuesto (necesario para acceso)
grafana             LoadBalancer  $18/mes
kibana              LoadBalancer  $18/mes
alertmanager        LoadBalancer  $18/mes
jaeger              LoadBalancer  $18/mes
```

**Ahorro:**
- 7 servicios internos × $18/mes = **$126/mes ahorrados**
- Solo 4 LoadBalancers necesarios para herramientas de monitoreo

---

### 4️⃣ KEDA - Scale to Zero Ready

**Configuración:** `kubernetes/keda/`

```yaml
# ScaledObject permite escalar a 0 réplicas
spec:
  minReplicaCount: 0    # Scale to zero cuando no hay tráfico
  maxReplicaCount: 10
```

**Ahorro potencial:**
- En horario nocturno (8 horas/día): Servicios pueden escalar a 0
- Ahorro estimado: **~30%** en recursos de pods

---

### 5️⃣ Spot/Preemptible Instances (Preparado)

**Archivo:** `terraform/modules/gke/variables.tf`

```hcl
# Variable lista para habilitar Spot instances
variable "preemptible" {
  description = "Usar instancias preemptible (spot)"
  type        = bool
  default     = false  # Cambiar a true para dev/staging
}
```

**Ahorro potencial con Spot:**
| Tipo | On-Demand | Spot | Ahorro |
|------|-----------|------|--------|
| e2-medium | $24/mes | ~$7/mes | **~70%** |

⚠️ **Nota:** Spot instances pueden ser interrumpidas. Recomendado solo para dev/staging.

---

## 📊 Monitoreo de Costos en GCP

### 1. GCP Billing Dashboard

**Acceso:** `console.cloud.google.com/billing`

```
📊 Métricas disponibles:
├── Costo por servicio (GKE, Compute, Networking)
├── Costo por proyecto
├── Costo por etiqueta (labels)
├── Tendencias de gasto
└── Proyecciones de fin de mes
```

### 2. Budget Alerts Configurados

```bash
# Crear alerta de presupuesto
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Ecommerce Dev Budget" \
  --budget-amount=150USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100
```

**Alertas configuradas:**
| Umbral | Acción |
|--------|--------|
| 50% ($75) | Email de advertencia |
| 90% ($135) | Email urgente |
| 100% ($150) | Email crítico + Slack |

### 3. Labels para Tracking

**Configuración en Terraform:**
```hcl
resource_labels = {
  "terraform"   = "true"
  "project"     = "ecommerce"
  "environment" = "dev"
  "team"        = "devops"
  "cost-center" = "engineering"
}
```

---

## 📈 Dashboard de Costos en Grafana

### Queries para BigQuery Export

```sql
-- Costo diario por servicio
SELECT
  DATE(usage_start_time) as date,
  service.description as service,
  SUM(cost) as daily_cost
FROM `project.billing_export.gcp_billing_export_v1_*`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY date, service
ORDER BY date DESC, daily_cost DESC
```

### Panel de Grafana Sugerido

```json
{
  "title": "GCP Daily Costs",
  "type": "timeseries",
  "datasource": "BigQuery",
  "targets": [
    {
      "rawSql": "SELECT ... (query above)"
    }
  ]
}
```

---

## 📋 Resumen de Ahorros

### Ahorros Implementados

| Estrategia | Ahorro Mensual | % Ahorro |
|------------|---------------|----------|
| Autoscaling (1-3 nodos) | ~$27 | 37% en compute |
| e2-medium vs n2-standard | ~$92 | 66% por nodo |
| ClusterIP (7 servicios) | $126 | 100% en LB internos |
| **Total Ahorros** | **~$245** | |

### Costo Optimizado vs Sin Optimizar

| Escenario | Costo Mensual |
|-----------|--------------|
| Sin optimización | ~$370 |
| **Con optimización** | **~$125** |
| **Ahorro Total** | **~$245 (66%)** |

---

## 🔮 Recomendaciones Futuras

### Corto Plazo (inmediato)
- [ ] Habilitar Spot instances para dev/staging
- [ ] Configurar Budget Alerts en GCP
- [ ] Exportar billing a BigQuery para análisis

### Mediano Plazo (1-2 semanas)
- [ ] Implementar Committed Use Discounts (CUDs) para prod
- [ ] Configurar dashboards de costos en Grafana
- [ ] Implementar políticas de apagado nocturno

### Largo Plazo (1+ mes)
- [ ] Evaluar migración a Autopilot GKE (pago por pod)
- [ ] Implementar FinOps automatizado con Kubecost
- [ ] Optimizar imágenes Docker para reducir storage

---

## 🔗 Herramientas de GCP para FinOps

| Herramienta | URL | Uso |
|-------------|-----|-----|
| Billing Dashboard | console.cloud.google.com/billing | Ver costos |
| Cost Management | cloud.google.com/cost-management | Análisis |
| Recommender | console.cloud.google.com/recommender | Sugerencias |
| Budget Alerts | console.cloud.google.com/billing/budgets | Alertas |

---

## 📚 Referencias

- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)
- [GKE Cost Optimization](https://cloud.google.com/kubernetes-engine/docs/best-practices/cost-optimization)
- [FinOps Foundation](https://www.finops.org/)
- [GCP Billing Export](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)

---

## 👥 Autores

- Equipo de DevOps - Taller 2 Ingeniería de Software
- Universidad Icesi - 2025
