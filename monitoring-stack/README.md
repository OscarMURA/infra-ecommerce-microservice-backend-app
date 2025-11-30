# 📊 Stack de Observabilidad y Monitoreo - E-Commerce Microservices# 📊 Monitoring Stack - Prometheus + Grafana + AlertManager + EFK



> **Taller 2 - Ingeniería de Software**  Stack completo de **Observabilidad y Monitoreo** para los microservicios de E-Commerce desplegado en GKE usando Terraform y manifests de Kubernetes.

> Implementación completa del 10% correspondiente a **Observabilidad y Monitoreo**

## ✅ Estado Actual del Despliegue

Stack completo de observabilidad para los microservicios de E-Commerce desplegado en **Google Kubernetes Engine (GKE)** usando Terraform, Helm y manifests de Kubernetes.

| Componente | Estado | Tipo | Notas |

---|------------|--------|------|-------|

| **Grafana** | ✅ Running | LoadBalancer | Dashboards y visualización |

## 📋 Checklist de Requisitos (10% - Observabilidad y Monitoreo)| **Prometheus Server** | ✅ Running | ClusterIP | Recolección de métricas |

| **AlertManager** | ✅ Running | LoadBalancer | Gestión de alertas |

| # | Requisito | Estado | Implementación || **Node Exporter** | ✅ Running | ClusterIP | Métricas de nodos |

|---|-----------|--------|----------------|| **Elasticsearch** | ✅ Running | ClusterIP | Almacenamiento de logs |

| 1 | Implementar stack de monitoreo con Prometheus y Grafana | ✅ | Helm charts + Terraform || **Kibana** | ✅ Running | LoadBalancer | Visualización de logs |

| 2 | Configurar ELK Stack para gestión de logs | ✅ | EFK (Elasticsearch + Fluentd + Kibana) || **Fluentd** | ✅ Running | DaemonSet | Recolección de logs |

| 3 | Implementar dashboards relevantes para cada servicio | ✅ | 2 dashboards (técnico + negocio) |

| 4 | Configurar alertas para situaciones críticas | ✅ | 7 reglas de alertas + AlertManager |## 🌐 URLs de Acceso

| 5 | Implementar tracing distribuido | ✅ | Jaeger + Spring Cloud Sleuth |

| 6 | Configurar health checks y readiness/liveness probes | ✅ | Actuator + K8s probes || Servicio | URL | Credenciales |

| 7 | Implementar métricas de negocio además de técnicas | ✅ | Dashboard de Business Metrics ||----------|-----|--------------|

| **Grafana** | http://34.121.2.178 | admin / admin123 |

---| **AlertManager** | http://34.57.30.187:9093 | N/A |

| **Kibana** | http://34.71.123.62:5601 | N/A |

## 🏗️ Arquitectura de Observabilidad| **Prometheus** | Port-forward → http://localhost:9090 | N/A |



```## 📊 Dashboards de Grafana

                              ┌─────────────────────────────────────────────────────────────┐

                              │                    OBSERVABILITY STACK                       │| Dashboard | UID | Descripción |

                              └─────────────────────────────────────────────────────────────┘|-----------|-----|-------------|

                                                          │| E-Commerce Microservices v2 | `ecommerce-v2` | Métricas técnicas (JVM, CPU, memoria) |

          ┌───────────────────────────────────────────────┼───────────────────────────────────────────────┐| E-Commerce Business Metrics | `ecommerce-business` | Métricas de negocio (órdenes, pagos, etc.) |

          │                                               │                                               │

          ▼                                               ▼                                               ▼### URLs Directas

┌─────────────────────┐                      ┌─────────────────────┐                      ┌─────────────────────┐- **Dashboard Técnico:** http://34.121.2.178/d/ecommerce-v2/e-commerce-microservices-v2

│      MÉTRICAS       │                      │        LOGS         │                      │      TRACING        │- **Dashboard de Negocio:** http://34.121.2.178/d/ecommerce-business/e-commerce-business-metrics

│   (Prometheus)      │                      │    (EFK Stack)      │                      │     (Jaeger)        │

└─────────────────────┘                      └─────────────────────┘                      └─────────────────────┘### 📸 Screenshots

          │                                               │                                               │

          ▼                                               ▼                                               ▼#### Dashboard E-Commerce Microservices v2

┌─────────────────────┐                      ┌─────────────────────┐                      ┌─────────────────────┐

│  Prometheus Server  │                      │   Elasticsearch     │                      │  Jaeger Collector   │**Service Status - Todos los servicios UP:**

│  - Scrape métricas  │                      │   - Almacena logs   │                      │  - Recibe spans     │![Service Status](docs/screenshots/grafana-service-status.png)

│  - Evalúa reglas    │                      │   - Indexa datos    │                      │  - Almacena trazas  │

└─────────────────────┘                      └─────────────────────┘                      └─────────────────────┘| Servicio | Estado |

          │                                               │                                               │|----------|--------|

          ▼                                               ▼                                               ▼| User Service | 🟢 UP |

┌─────────────────────┐                      ┌─────────────────────┐                      ┌─────────────────────┐| Order Service | 🟢 UP |

│      Grafana        │                      │       Kibana        │                      │     Jaeger UI       │| Product Service | 🟢 UP |

│  - Visualización    │                      │  - Visualización    │                      │  - Visualización    │| Payment Service | 🟢 UP |

│  - Dashboards       │                      │  - Búsqueda logs    │                      │  - Trace timeline   │| Shipping Service | 🟢 UP |

└─────────────────────┘                      └─────────────────────┘                      └─────────────────────┘| Favourite Service | 🟢 UP |

          │                                               ▲                                               ▲| Service Discovery | 🟢 UP |

          ▼                                               │                                               │

┌─────────────────────┐                      ┌─────────────────────┐                      ┌─────────────────────┐**JVM Metrics:**

│    AlertManager     │                      │      Fluentd        │                      │  Spring Sleuth +    │- JVM Heap Memory Used: 233-371 MiB por servicio

│  - Routing alertas  │                      │  - DaemonSet        │                      │  Zipkin Reporter    │- JVM Live Threads: ~30 threads por servicio

│  - Notificaciones   │                      │  - Recolecta logs   │                      │  - Genera spans     │

└─────────────────────┘                      └─────────────────────┘                      └─────────────────────┘**HTTP Request Metrics:**

          ▲                                               ▲                                               ▲- HTTP Request Rate: 0.7-0.87 req/s

          │                                               │                                               │- HTTP Response Time: 1.4-3.3 ms promedio

          └───────────────────────────────────────────────┼───────────────────────────────────────────────┘

                                                          │**System Metrics:**

                              ┌─────────────────────────────────────────────────────────────┐- System CPU Usage: 2-15%

                              │                     MICROSERVICIOS                           │- HikariCP Database Connections: Pool activo

                              │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │

                              │  │  User   │ │ Product │ │  Order  │ │ Payment │           │## 🚨 Sistema de Alertas

                              │  │ Service │ │ Service │ │ Service │ │ Service │  + 3 más  │

                              │  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │### Alertas Configuradas

                              │       │           │           │           │                 │

                              │       └───────────┴───────────┴───────────┘                 │| Alerta | Condición | Severidad | Descripción |

                              │                         │                                   │|--------|-----------|-----------|-------------|

                              │              /actuator/prometheus                           │| `ServiceDown` | Servicio no responde por 1min | 🔴 critical | Un microservicio está caído |

                              │              /actuator/health                               │| `PodRestarting` | >3 reinicios en 15min | 🟡 warning | Pod reiniciándose frecuentemente |

                              └─────────────────────────────────────────────────────────────┘| `HighLatency` | P95 > 2s por 5min | 🟡 warning | Alta latencia en respuestas |

```| `HighErrorRate` | Errores > 5% por 5min | 🔴 critical | Alta tasa de errores HTTP 5xx |

| `HighMemoryUsage` | Heap > 80% por 5min | 🟡 warning | Alto uso de memoria JVM |

---| `HighCpuUsage` | CPU > 80% por 10min | 🟡 warning | Alto uso de CPU |

| `DatabaseConnectionPoolExhausted` | Pool DB > 80% | 🟡 warning | Pool de conexiones casi lleno |

## 🌐 URLs de Acceso

### Arquitectura de Alertas

| Servicio | URL | Credenciales | Propósito |

|----------|-----|--------------|-----------|```

| **Grafana** | http://34.121.2.178 | admin / admin123 | Dashboards y métricas |┌─────────────┐     ┌──────────────┐     ┌──────────────┐

| **Kibana** | http://34.71.123.62:5601 | N/A | Logs centralizados |│  Prometheus │────▶│ AlertManager │────▶│  Receptores  │

| **Jaeger** | http://104.154.243.214:16686 | N/A | Tracing distribuido |│   (reglas)  │     │  (routing)   │     │  (webhook)   │

| **AlertManager** | http://34.57.30.187:9093 | N/A | Gestión de alertas |└─────────────┘     └──────────────┘     └──────────────┘

                           │

---                    ┌──────┴──────┐

                    │  Inhibición │

## 1️⃣ Stack de Monitoreo: Prometheus + Grafana                    │  & Agrupado │

                    └─────────────┘

### Componentes Desplegados```



| Componente | Versión | Estado | Tipo de Servicio |### Rutas de Alertas

|------------|---------|--------|------------------|

| Prometheus Server | v2.48.0 | ✅ Running | ClusterIP |```yaml

| Grafana | 10.2.0 | ✅ Running | LoadBalancer |route:

| Node Exporter | v1.7.0 | ✅ Running | ClusterIP |  receiver: default-receiver

| AlertManager | v0.26.0 | ✅ Running | LoadBalancer |  group_by: [alertname, namespace, service]

  routes:

### Configuración de Prometheus    - match: {severity: critical}

      receiver: critical-receiver

Prometheus está configurado para scrapear métricas de:      group_wait: 10s

      repeat_interval: 1h

```yaml    - match: {severity: warning}

# prometheus.yml - Jobs configurados      receiver: warning-receiver

scrape_configs:      group_wait: 1m

  - job_name: 'ecommerce-prod'      # Microservicios en producción      repeat_interval: 4h

  - job_name: 'ecommerce-staging'   # Microservicios en staging```

  - job_name: 'kubernetes-pods'     # Todos los pods con anotaciones

  - job_name: 'kubernetes-nodes'    # Métricas de nodos### Reglas de Inhibición

```

- Si `ServiceDown` → suprime `HighLatency` (mismo servicio)

### Anotaciones en Pods para Scraping- Si alerta `critical` → suprime alertas `warning` (mismo namespace)



Todos los microservicios tienen las siguientes anotaciones:## 📋 Prerequisitos



```yaml- [x] `gcloud` CLI instalado y autenticado

metadata:- [x] `terraform` instalado (>= 1.0.0)

  annotations:- [x] `kubectl` instalado

    prometheus.io/scrape: "true"- [x] `helm` instalado

    prometheus.io/port: "8085"      # Puerto del servicio- [x] Cluster GKE existente en GCP

    prometheus.io/path: "/actuator/prometheus"

```## 🚀 Uso Rápido



### Verificación de Targets### Desplegar el Stack



```bash```bash

# Ver targets activos en Prometheus# 1. Navegar al directorio de terraform

kubectl port-forward svc/prometheus-server 9090:80 -n monitoringcd monitoring-stack/terraform

# Acceder a: http://localhost:9090/targets

```# 2. Inicializar Terraform

terraform init

---

# 3. Ver el plan

## 2️⃣ EFK Stack: Gestión de Logsterraform plan



### Arquitectura EFK# 4. Aplicar (desplegar)

terraform apply -auto-approve

``````

┌──────────────────────────────────────────────────────────────────────┐

│                           EFK STACK                                   │### Acceder a los Servicios

├──────────────────────────────────────────────────────────────────────┤

│                                                                       │```bash

│   ┌─────────────┐         ┌─────────────────┐         ┌───────────┐  │# Grafana - ya tiene IP externa

│   │   Fluentd   │────────▶│  Elasticsearch  │◀────────│  Kibana   │  │# Acceder directamente a: http://34.121.2.178

│   │ (DaemonSet) │         │   (Storage)     │         │   (UI)    │  │

│   └─────────────┘         └─────────────────┘         └───────────┘  │# Prometheus - crear port-forward

│         ▲                                                             │kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

│         │                                                             │# Luego acceder a: http://localhost:9090

│   ┌─────┴─────┐                                                       │```

│   │ Container │  /var/log/containers/*.log                           │

│   │   Logs    │  /var/log/pods/**/*.log                              │## 📁 Estructura

│   └───────────┘                                                       │

│                                                                       │```

└──────────────────────────────────────────────────────────────────────┘monitoring-stack/

```├── README.md                     # Esta documentación

├── deploy.sh                     # Script helper para despliegue completo

### Componentes├── deploy-alerting.sh            # Script para desplegar alertas

├── deploy-efk.sh                 # Script para desplegar EFK Stack

| Componente | Versión | Imagen Docker | Función |├── setup-grafana.sh              # Script para configurar Grafana

|------------|---------|---------------|---------|├── setup-prometheus-annotations.sh # Script para anotaciones

| **Elasticsearch** | 7.17.16 | `elasticsearch:7.17.16` | Almacenamiento y búsqueda de logs |├── add-prometheus-dependencies.sh  # Script para dependencias

| **Fluentd** | 1.16 | `fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch7-1` | Recolección de logs |├── alertmanager/

| **Kibana** | 7.17.16 | `kibana:7.17.16` | Visualización y análisis |│   ├── configmap.yaml            # Configuración de AlertManager

│   └── deployment.yaml           # Deployment y Service

### Índices de Logs├── prometheus-rules/

│   └── alerting-rules.yaml       # Reglas de alertas detalladas

Los logs se almacenan en índices diarios:├── grafana-dashboards/

```│   ├── ecommerce-v2.json         # Dashboard técnico

ecommerce-logs-2025.11.30│   └── ecommerce-business.json   # Dashboard de métricas de negocio

ecommerce-logs-2025.11.29├── efk-stack/

...│   ├── elasticsearch.yaml        # Elasticsearch 7.17 Deployment

```│   ├── kibana.yaml               # Kibana 7.17 Deployment + LoadBalancer

│   └── fluentd.yaml              # Fluentd DaemonSet + ConfigMap

### Configuración de Fluentd└── terraform/

    ├── versions.tf               # Versiones de providers

```yaml    ├── variables.tf              # Variables configurables

# fluentd-configmap.yaml    ├── providers.tf              # Conexión a GCP/GKE

<match **>    ├── main.tf                   # Recursos (Prometheus + Grafana via Helm)

  @type elasticsearch    ├── outputs.tf                # Outputs e instrucciones

  host elasticsearch.monitoring.svc.cluster.local    └── terraform.tfvars          # Valores de tu proyecto

  port 9200```

  logstash_format true

  logstash_prefix ecommerce-logs## ⚙️ Configuración

  include_tag_key true

  type_name _docEdita `terraform/terraform.tfvars` con tus valores:

  flush_interval 5s

</match>```hcl

```# Tu proyecto GCP

project_id   = "devops-activity"

### Configurar Kibana (Data View)zone         = "us-central1-a"

cluster_name = "ecommerce-dev-gke-v2"

1. Acceder a **Kibana**: http://34.71.123.62:5601

2. Ir a **Stack Management** → **Data Views**# Password de Grafana (CAMBIAR en producción)

3. Crear nuevo Data View:grafana_admin_password = "admin123"

   - **Name**: `ecommerce-logs`

   - **Index pattern**: `ecommerce-logs-*`# Exponer servicios externamente

   - **Time field**: `@timestamp`expose_grafana    = true   # LoadBalancer

4. Ir a **Discover** para explorar logsexpose_prometheus = false  # ClusterIP (acceso vía port-forward)

```

### Filtros Útiles en Kibana

## 🔧 Comandos Útiles

| Filtro | Query |

|--------|-------|```bash

| Por servicio | `kubernetes.pod_name: *user-service*` |# Ver pods del stack

| Por namespace | `kubernetes.namespace_name: prod` |kubectl get pods -n monitoring

| Errores | `log: *ERROR*` |

| Warnings | `log: *WARN*` |# Ver servicios

| HTTP 5xx | `log: *status=5*` |kubectl get svc -n monitoring

| Trace IDs | `log: *traceId*` |

# Ver logs de Grafana

### Comandos de Verificaciónkubectl logs -l app.kubernetes.io/name=grafana -n monitoring



```bash# Ver logs de Prometheus

# Ver pods del EFK Stackkubectl logs -l app.kubernetes.io/name=prometheus -n monitoring -c prometheus-server

kubectl get pods -n monitoring -l 'app in (elasticsearch,kibana,fluentd)'

# Ver logs de AlertManager

# Verificar índices en Elasticsearchkubectl logs -l app=alertmanager -n monitoring

kubectl exec -n monitoring deploy/elasticsearch -- \

  curl -s localhost:9200/_cat/indices?v# Port-forward Prometheus

kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

# Contar documentos

kubectl exec -n monitoring deploy/elasticsearch -- \# Port-forward Alertmanager (si no tiene LoadBalancer)

  curl -s "localhost:9200/ecommerce-logs-*/_count" | jq .countkubectl port-forward svc/alertmanager 9093:9093 -n monitoring

```

# Ver logs de Fluentd

kubectl logs -n monitoring -l app=fluentd --tail=50## 🚨 Comandos de Alertas

```

```bash

---# Ver alertas activas en Prometheus

kubectl exec -n monitoring deployment/prometheus-server -- \

## 3️⃣ Dashboards de Grafana  wget -qO- "http://localhost:9090/api/v1/alerts" | jq '.data.alerts'



### Dashboard 1: E-Commerce Microservices v2 (Técnico)# Ver reglas de alertas cargadas

kubectl exec -n monitoring deployment/prometheus-server -- \

**URL**: http://34.121.2.178/d/ecommerce-v2/e-commerce-microservices-v2  wget -qO- "http://localhost:9090/api/v1/rules" | jq '.data.groups[].name'



| Panel | Métricas | Descripción |# Verificar conexión Prometheus → AlertManager

|-------|----------|-------------|kubectl exec -n monitoring deployment/prometheus-server -- \

| **Service Status** | `up{job="ecommerce-prod"}` | Estado UP/DOWN de cada servicio |  wget -qO- "http://localhost:9090/api/v1/alertmanagers" | jq '.'

| **HTTP Request Rate** | `rate(http_server_requests_seconds_count[5m])` | Requests por segundo |

| **HTTP Response Time** | `histogram_quantile(0.95, ...)` | Latencia P95 |# Ver estado de AlertManager

| **JVM Heap Memory** | `jvm_memory_used_bytes{area="heap"}` | Uso de memoria heap |kubectl exec -n monitoring deployment/alertmanager -- \

| **JVM Threads** | `jvm_threads_live_threads` | Threads activos |  wget -qO- "http://localhost:9093/api/v2/status" | jq '.'

| **System CPU** | `process_cpu_usage` | Uso de CPU por servicio |```

| **HikariCP Connections** | `hikaricp_connections_active` | Pool de conexiones DB |

| **GC Pause Time** | `jvm_gc_pause_seconds_sum` | Tiempo de Garbage Collection |## 🧪 Simular una Alerta (Testing)



### Dashboard 2: E-Commerce Business Metrics (Negocio)```bash

# Escalar un servicio a 0 para disparar ServiceDown

**URL**: http://34.121.2.178/d/ecommerce-business/e-commerce-business-metricskubectl scale deployment/payment-service -n prod --replicas=0



| Panel | Métrica | Descripción |# Esperar 1-2 minutos y verificar en:

|-------|---------|-------------|# - Prometheus: http://localhost:9090/alerts (via port-forward)

| **Órdenes por Segundo** | `rate(http_server_requests_seconds_count{uri="/api/orders",method="POST"}[5m])` | Nuevas órdenes |# - AlertManager: http://34.57.30.187:9093/#/alerts

| **Pagos por Segundo** | `rate(http_server_requests_seconds_count{uri=~"/api/payments.*",method="POST"}[5m])` | Pagos procesados |

| **Consultas de Productos** | `rate(http_server_requests_seconds_count{uri="/api/products",method="GET"}[5m])` | Búsquedas de productos |# Restaurar el servicio

| **Usuarios Activos** | `rate(http_server_requests_seconds_count{application="user-service"}[5m])` | Actividad de usuarios |kubectl scale deployment/payment-service -n prod --replicas=1

| **Tasa de Errores Global** | `sum(rate(...{status=~"5.."}[5m])) / sum(rate(...[5m]))` | % de errores HTTP 5xx |```

| **Latencia P95 Global** | `histogram_quantile(0.95, sum(rate(...[5m])) by (le))` | Latencia percentil 95 |

| **Favoritos Agregados** | `rate(http_server_requests_seconds_count{uri="/api/favourites",method="POST"}[5m])` | Items agregados a favoritos |## 🗑️ Destruir el Stack

| **Envíos Procesados** | `rate(http_server_requests_seconds_count{uri=~"/api/shippings.*"}[5m])` | Órdenes enviadas |

```bash

### Paneles por Serviciocd monitoring-stack/terraform

terraform destroy -auto-approve

Cada servicio tiene paneles específicos mostrando:

# También eliminar recursos manuales de alerting

```kubectl delete -f alertmanager/

┌────────────────────────────────────────────────────────────────────────┐kubectl delete -f prometheus-rules/

│                    USER-SERVICE DASHBOARD                               │```

├────────────────────────────────────────────────────────────────────────┤

│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │## 📈 Métricas Disponibles

│ │    Status    │ │ Request Rate │ │   Latency    │ │    Memory    │   │

│ │     🟢 UP    │ │  0.87 req/s  │ │    2.1ms     │ │   312 MiB    │   │### Métricas Técnicas (JVM/Spring Boot)

│ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │- `jvm_memory_used_bytes` - Uso de memoria

│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │- `jvm_gc_pause_seconds` - Pausas de GC

│ │     CPU      │ │   Threads    │ │   DB Pool    │ │  Error Rate  │   │- `process_cpu_usage` - Uso de CPU

│ │     8%       │ │     32       │ │    5/10      │ │     0%       │   │- `hikaricp_connections_*` - Pool de conexiones DB

│ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │- `http_server_requests_seconds_*` - Latencia HTTP

└────────────────────────────────────────────────────────────────────────┘

```### Métricas de Negocio

- Órdenes por segundo (`http_server_requests` en ORDER-SERVICE POST)

---- Pagos por segundo (`http_server_requests` en PAYMENT-SERVICE POST)

- Consultas de productos (`http_server_requests` en PRODUCT-SERVICE GET)

## 4️⃣ Sistema de Alertas- Actividad de usuarios (`http_server_requests` en USER-SERVICE)

- Tasa de errores global (status 5xx)

### Alertas Configuradas- Latencia P95 global



| Alerta | Expresión PromQL | Duración | Severidad |## 📊 Imágenes Docker Utilizadas

|--------|-----------------|----------|-----------|

| **ServiceDown** | `up{job="ecommerce-prod"} == 0` | 1 min | 🔴 critical |El stack usa imágenes de **Docker Hub** para evitar problemas de conectividad con otros registries:

| **PodRestarting** | `increase(kube_pod_container_status_restarts_total[15m]) > 3` | 5 min | 🟡 warning |

| **HighLatency** | `histogram_quantile(0.95, ...) > 2` | 5 min | 🟡 warning || Componente | Imagen |

| **HighErrorRate** | `rate(...{status=~"5.."}[5m]) / rate(...[5m]) > 0.05` | 5 min | 🔴 critical ||------------|--------|

| **HighMemoryUsage** | `jvm_memory_used_bytes / jvm_memory_max_bytes > 0.8` | 5 min | 🟡 warning || Prometheus | `prom/prometheus:v2.48.0` |

| **HighCpuUsage** | `process_cpu_usage > 0.8` | 10 min | 🟡 warning || Alertmanager | `prom/alertmanager:v0.26.0` |

| **DBPoolExhausted** | `hikaricp_connections_active / hikaricp_connections_max > 0.8` | 5 min | 🟡 warning || Node Exporter | `prom/node-exporter:v1.7.0` |

| ConfigMap Reload | `jimmidyson/configmap-reload:v0.9.0` |

### Archivo de Reglas de Alertas| Grafana | `grafana/grafana:10.2.0` |



```yaml## 🔄 Despliegue de Alertas (Reproducible)

# prometheus-rules/alerting-rules.yaml

groups:Para desplegar solo el sistema de alertas en un cluster existente:

  - name: service-availability

    rules:```bash

      - alert: ServiceDowncd monitoring-stack

        expr: up{job="ecommerce-prod"} == 0

        for: 1m# 1. Aplicar ConfigMap y Deployment de AlertManager

        labels:kubectl apply -f alertmanager/

          severity: critical

        annotations:# 2. Aplicar reglas de alertas a Prometheus

          summary: "Servicio {{ $labels.application }} está caído"kubectl apply -f prometheus-rules/

          description: "El servicio {{ $labels.application }} no responde desde hace 1 minuto"

# 3. Importar dashboard de métricas de negocio

      - alert: PodRestarting# Opción A: Manualmente en Grafana UI → Import → Upload JSON

        expr: increase(kube_pod_container_status_restarts_total{namespace=~"prod|staging"}[15m]) > 3# Opción B: Via API

        for: 5mGRAFANA_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

        labels:curl -X POST "http://admin:admin123@${GRAFANA_IP}/api/dashboards/db" \

          severity: warning  -H "Content-Type: application/json" \

        annotations:  -d "{\"dashboard\": $(cat grafana-dashboards/ecommerce-business.json), \"overwrite\": true}"

          summary: "Pod {{ $labels.pod }} reiniciándose frecuentemente"

# 4. Reiniciar Prometheus para cargar la conexión con AlertManager

  - name: performancekubectl rollout restart deployment/prometheus-server -n monitoring

    rules:```

      - alert: HighLatency

        expr: histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket{namespace=~"prod|staging"}[5m])) by (le, application)) > 2## ⚠️ Notas Importantes

        for: 5m

        labels:1. **Persistencia deshabilitada**: Los datos se pierden si los pods se reinician. Para producción, habilitar PVC.

          severity: warning

        annotations:2. **Kube-state-metrics deshabilitado**: Por problemas de conectividad con `registry.k8s.io` desde GKE.

          summary: "Alta latencia en {{ $labels.application }}"

          description: "Latencia P95 > 2 segundos"3. **Plugins de Grafana**: Deshabilitados para evitar timeouts al descargar de grafana.com.



      - alert: HighErrorRate4. **Autenticación**: El Terraform usa `gcloud auth print-access-token` automáticamente.

        expr: sum(rate(http_server_requests_seconds_count{status=~"5..",namespace=~"prod|staging"}[5m])) by (application) / sum(rate(http_server_requests_seconds_count{namespace=~"prod|staging"}[5m])) by (application) > 0.05

        for: 5m## 🔍 Troubleshooting

        labels:

          severity: critical### Error: "cluster not found"

        annotations:```bash

          summary: "Alta tasa de errores en {{ $labels.application }}"# Verificar que el cluster existe

          description: "Más del 5% de requests retornan error 5xx"gcloud container clusters list



  - name: resources# Actualizar credenciales

    rules:gcloud container clusters get-credentials ecommerce-dev-gke-v2 --zone us-central1-a

      - alert: HighMemoryUsage```

        expr: sum(jvm_memory_used_bytes{area="heap"}) by (application) / sum(jvm_memory_max_bytes{area="heap"}) by (application) > 0.8

        for: 5m### Pods en estado ImagePullBackOff

        labels:```bash

          severity: warning# Verificar eventos del pod

        annotations:kubectl describe pod <pod-name> -n monitoring

          summary: "Alto uso de memoria en {{ $labels.application }}"

# El cluster puede tener problemas de red con ciertos registries

      - alert: HighCpuUsage# La configuración actual usa Docker Hub para evitar esto

        expr: process_cpu_usage{namespace=~"prod|staging"} > 0.8```

        for: 10m

        labels:### No puedo acceder a Grafana

          severity: warning```bash

        annotations:# Verificar IP externa

          summary: "Alto uso de CPU en {{ $labels.application }}"kubectl get svc grafana -n monitoring



  - name: database# Si no tiene IP externa, usar port-forward

    rules:kubectl port-forward svc/grafana 3000:80 -n monitoring

      - alert: DatabaseConnectionPoolExhausted```

        expr: hikaricp_connections_active / hikaricp_connections_max > 0.8

        for: 5m### Prometheus server en CrashLoopBackOff

        labels:```bash

          severity: warning# Generalmente es el sidecar configmap-reload

        annotations:# El servidor principal debería estar funcionando

          summary: "Pool de conexiones DB casi lleno en {{ $labels.application }}"kubectl logs <prometheus-pod> -n monitoring -c prometheus-server

``````



### Configuración de AlertManager## 📚 Referencias



```yaml- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)

# alertmanager/configmap.yaml- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

global:- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

  resolve_timeout: 5m- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)

- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

route:

  receiver: default-receiver---

  group_by: [alertname, namespace, service]

  group_wait: 30s## 📋 Checklist de Observabilidad

  group_interval: 5m

  repeat_interval: 4h- [x] Prometheus desplegado y recolectando métricas

  routes:- [x] Grafana con dashboards configurados

    - match:- [x] AlertManager desplegado y conectado a Prometheus

        severity: critical- [x] 7 reglas de alertas configuradas

      receiver: critical-receiver- [x] Dashboard de métricas técnicas (JVM, CPU, memoria)

      group_wait: 10s- [x] Dashboard de métricas de negocio (órdenes, pagos)

      repeat_interval: 1h- [x] Health checks y readiness/liveness probes en servicios

    - match:- [x] 7/7 microservicios exponiendo métricas Prometheus

        severity: warning- [x] EFK Stack para gestión de logs (Elasticsearch + Fluentd + Kibana)

      receiver: warning-receiver- [ ] Tracing distribuido con Jaeger/Zipkin (opcional)

      group_wait: 1m

      repeat_interval: 4h---



inhibit_rules:## 📝 EFK Stack - Gestión de Logs

  - source_match:

      alertname: ServiceDown### Arquitectura

    target_match:

      alertname: HighLatency```

    equal: [application]┌─────────────┐     ┌──────────────┐     ┌──────────────┐

  - source_match:│   Fluentd   │────▶│Elasticsearch │◀────│   Kibana     │

      severity: critical│ (DaemonSet) │     │  (Storage)   │     │   (UI)       │

    target_match:└─────────────┘     └──────────────┘     └──────────────┘

      severity: warning       ▲

    equal: [namespace]       │

┌──────┴──────┐

receivers:│  Container  │

  - name: default-receiver│    Logs     │

    webhook_configs:│ /var/log/*  │

      - url: 'http://localhost:5001/'└─────────────┘

        send_resolved: true```

  - name: critical-receiver

    webhook_configs:### Componentes

      - url: 'http://localhost:5001/critical'

        send_resolved: true| Componente | Versión | Función |

  - name: warning-receiver|------------|---------|---------|

    webhook_configs:| **Elasticsearch** | 7.17.16 | Almacenamiento y búsqueda de logs |

      - url: 'http://localhost:5001/warning'| **Fluentd** | 1.16 | Recolección de logs de todos los pods |

        send_resolved: true| **Kibana** | 7.17.16 | Visualización y análisis de logs |

```

### Índices de Logs

### Simular una Alerta (Testing)

Los logs se almacenan en índices diarios con el formato:

```bash```

# Escalar payment-service a 0 para disparar ServiceDownecommerce-logs-YYYY.MM.DD

kubectl scale deployment/payment-service -n prod --replicas=0```



# Esperar 1-2 minutos y verificar en:### Desplegar EFK Stack

# - AlertManager: http://34.57.30.187:9093/#/alerts

# - Prometheus: kubectl port-forward svc/prometheus-server 9090:80 -n monitoring```bash

#   Luego: http://localhost:9090/alertscd monitoring-stack



# Restaurar el servicio# Despliegue completo

kubectl scale deployment/payment-service -n prod --replicas=1./deploy-efk.sh

```

# O manualmente:

---kubectl apply -f efk-stack/

```

## 5️⃣ Tracing Distribuido con Jaeger

### Configurar Kibana

### Arquitectura de Tracing

1. Acceder a Kibana: http://34.71.123.62:5601

```2. Ir a **Stack Management** → **Data Views**

┌─────────────────────────────────────────────────────────────────────────┐3. Crear nuevo Data View:

│                        DISTRIBUTED TRACING                               │   - Name: `ecommerce-logs`

├─────────────────────────────────────────────────────────────────────────┤   - Index pattern: `ecommerce-logs-*`

│                                                                          │   - Time field: `@timestamp`

│   ┌─────────────────┐                         ┌─────────────────┐       │4. Ir a **Discover** para ver los logs

│   │  Microservicio  │                         │     Jaeger      │       │

│   │  ┌───────────┐  │                         │  ┌───────────┐  │       │### Comandos Útiles - EFK

│   │  │  Sleuth   │──┼─────────────────────────┼─▶│ Collector │  │       │

│   │  │  Zipkin   │  │    HTTP POST            │  │  :9411    │  │       │```bash

│   │  │ Reporter  │  │    /api/v2/spans        │  └─────┬─────┘  │       │# Ver pods del EFK Stack

│   │  └───────────┘  │                         │        │        │       │kubectl get pods -n monitoring -l 'app in (elasticsearch, kibana, fluentd)'

│   └─────────────────┘                         │        ▼        │       │

│                                               │  ┌───────────┐  │       │# Ver logs de Fluentd

│   Genera:                                     │  │  Storage  │  │       │kubectl logs -n monitoring -l app=fluentd --tail=50

│   - Trace ID                                  │  │ (Memory)  │  │       │

│   - Span ID                                   │  └─────┬─────┘  │       │# Verificar índices en Elasticsearch

│   - Parent Span ID                            │        │        │       │kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -s localhost:9200/_cat/indices

│   - Timestamps                                │        ▼        │       │

│   - Tags                                      │  ┌───────────┐  │       │# Contar documentos en un índice

│                                               │  │  Query    │  │       │kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -s "localhost:9200/ecommerce-logs-*/_count"

│                                               │  │  :16686   │  │       │

│                                               │  └───────────┘  │       │# Buscar logs de un servicio específico

│                                               └─────────────────┘       │kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -s "localhost:9200/ecommerce-logs-*/_search?q=kubernetes.pod_name:*payment*&size=5"

│                                                                          │```

└─────────────────────────────────────────────────────────────────────────┘

```### Filtros Útiles en Kibana



### Componentes de Tracing- **Por servicio:** `kubernetes.pod_name: *payment-service*`

- **Por namespace:** `kubernetes.namespace_name: prod`

| Componente | Descripción |- **Por nivel de log:** `log: *ERROR*` o `log: *WARN*`

|------------|-------------|- **Errores HTTP:** `log: *5xx*` o `log: *4xx*`

| **Spring Cloud Sleuth** | Genera y propaga trace/span IDs automáticamente |

| **Zipkin Reporter** | Envía spans al collector Jaeger (compatible con API Zipkin) |### Imágenes Docker - EFK

| **Jaeger Collector** | Recibe spans vía HTTP en puerto 9411 |

| **Jaeger Query** | API y UI para consultar trazas || Componente | Imagen |

|------------|--------|

### Configuración en los Microservicios| Elasticsearch | `elasticsearch:7.17.16` |

| Kibana | `kibana:7.17.16` |

**Dependencias en `pom.xml`:**| Fluentd | `fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch7-1` |


```xml
<!-- Spring Cloud Sleuth for distributed tracing -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

**Configuración en `application.yml`:**

```yaml
spring:
  application:
    name: user-service  # Nombre que aparece en Jaeger
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://localhost:9411}
    enabled: true
  sleuth:
    sampler:
      probability: ${SPRING_SLEUTH_SAMPLER_PROBABILITY:1.0}  # 100% de trazas
```

**Variables de entorno en Kubernetes:**

```yaml
env:
  - name: SPRING_ZIPKIN_BASE_URL
    value: "http://jaeger-collector.monitoring.svc.cluster.local:9411"
  - name: SPRING_SLEUTH_SAMPLER_PROBABILITY
    value: "1.0"
```

### Servicios con Tracing Habilitado

| Servicio | spring.application.name | Estado |
|----------|------------------------|--------|
| user-service | `user-service` | ✅ Trazas activas |
| product-service | `product-service` | ✅ Trazas activas |
| order-service | `order-service` | ✅ Trazas activas |
| payment-service | `payment-service` | ✅ Trazas activas |
| shipping-service | `shipping-service` | ✅ Trazas activas |
| favourite-service | `favourite-service` | ✅ Trazas activas |
| service-discovery | `service-discovery` | ✅ Trazas activas |

### Usar Jaeger UI

1. **Acceder**: http://104.154.243.214:16686
2. **Seleccionar Service**: `user-service`, `product-service`, etc.
3. **Lookback**: Last 15 Minutes
4. **Find Traces**: Click para buscar

### Ejemplo de Traza

```
Trace ID: bdd7ad369b057bb9
├── user-service: GET /api/users/{userId}  [2.1ms]
│   ├── span: SELECT users  [0.8ms]
│   └── span: SELECT credentials  [0.4ms]
```

### Verificar Trazas vía API

```bash
# Listar servicios en Jaeger
curl -s "http://104.154.243.214:16686/api/services" | jq '.data'

# Obtener trazas de user-service
curl -s "http://104.154.243.214:16686/api/traces?service=user-service&limit=5" | jq '.data | length'

# Ver detalle de una traza
curl -s "http://104.154.243.214:16686/api/traces?service=user-service&limit=1" | jq '.data[0]'
```

---

## 6️⃣ Health Checks y Probes

### Configuración de Probes en Kubernetes

Todos los microservicios tienen configurados:

```yaml
# deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: user-service
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8085
            initialDelaySeconds: 120
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8085
            initialDelaySeconds: 60
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 5
```

### Tipos de Probes

| Probe | Propósito | Configuración |
|-------|-----------|---------------|
| **Liveness Probe** | Reinicia el pod si falla | Delay: 120s, Period: 10s |
| **Readiness Probe** | Remueve del load balancer si falla | Delay: 60s, Period: 5s |

### Endpoints de Spring Boot Actuator

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus,info
  endpoint:
    health:
      show-details: always
  health:
    circuitbreakers:
      enabled: true
```

### Verificar Health

```bash
# Health de un servicio
kubectl exec -n prod deploy/user-service -- curl -s http://localhost:8085/actuator/health | jq .

# Output esperado:
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "diskSpace": { "status": "UP" },
    "ping": { "status": "UP" },
    "circuitBreakers": { "status": "UP" }
  }
}
```

### Health Checks por Servicio

| Servicio | Endpoint | Puerto | Estado |
|----------|----------|--------|--------|
| user-service | `/actuator/health` | 8085 | ✅ UP |
| product-service | `/actuator/health` | 8083 | ✅ UP |
| order-service | `/actuator/health` | 8084 | ✅ UP |
| payment-service | `/actuator/health` | 8086 | ✅ UP |
| shipping-service | `/actuator/health` | 8087 | ✅ UP |
| favourite-service | `/actuator/health` | 8088 | ✅ UP |
| service-discovery | `/actuator/health` | 8761 | ✅ UP |

---

## 7️⃣ Métricas de Negocio

### Métricas Técnicas vs Negocio

| Categoría | Métricas |
|-----------|----------|
| **Técnicas** | CPU, Memoria, Threads, GC, Conexiones DB |
| **Negocio** | Órdenes/s, Pagos/s, Productos consultados, Favoritos agregados |

### Métricas de Negocio Implementadas

```promql
# Órdenes creadas por segundo
rate(http_server_requests_seconds_count{
  application="order-service",
  uri="/api/orders",
  method="POST",
  status="200"
}[5m])

# Pagos procesados por segundo
rate(http_server_requests_seconds_count{
  application="payment-service",
  uri=~"/api/payments.*",
  method="POST",
  status="200"
}[5m])

# Productos consultados por segundo
rate(http_server_requests_seconds_count{
  application="product-service",
  uri="/api/products",
  method="GET"
}[5m])

# Búsquedas de usuarios
rate(http_server_requests_seconds_count{
  application="user-service",
  uri=~"/api/users.*",
  method="GET"
}[5m])

# Favoritos agregados
rate(http_server_requests_seconds_count{
  application="favourite-service",
  uri="/api/favourites",
  method="POST"
}[5m])

# Envíos procesados
rate(http_server_requests_seconds_count{
  application="shipping-service",
  uri=~"/api/shippings.*"
}[5m])

# Tasa de éxito global
sum(rate(http_server_requests_seconds_count{status="200"}[5m])) 
/ 
sum(rate(http_server_requests_seconds_count[5m])) * 100

# Tiempo promedio de respuesta por operación de negocio
rate(http_server_requests_seconds_sum{uri="/api/orders",method="POST"}[5m])
/
rate(http_server_requests_seconds_count{uri="/api/orders",method="POST"}[5m])
```

### Métricas Expuestas por Actuator

```bash
# Ver todas las métricas disponibles
kubectl exec -n prod deploy/user-service -- \
  curl -s http://localhost:8085/actuator/prometheus | grep -E "^[a-z]" | cut -d'{' -f1 | sort -u

# Métricas HTTP
http_server_requests_seconds_count
http_server_requests_seconds_sum
http_server_requests_seconds_max

# Métricas JVM
jvm_memory_used_bytes
jvm_memory_max_bytes
jvm_threads_live_threads
jvm_gc_pause_seconds_count

# Métricas de Base de Datos
hikaricp_connections_active
hikaricp_connections_idle
hikaricp_connections_pending

# Métricas de Resilience4j
resilience4j_circuitbreaker_state
resilience4j_circuitbreaker_calls_total
resilience4j_bulkhead_available_concurrent_calls
```

---

## 📁 Estructura del Proyecto

```
monitoring-stack/
├── README.md                          # Esta documentación
├── deploy.sh                          # Script de despliegue completo
├── deploy-alerting.sh                 # Desplegar solo alertas
├── deploy-efk.sh                      # Desplegar solo EFK
├── setup-grafana.sh                   # Configurar Grafana
│
├── alertmanager/
│   ├── configmap.yaml                 # Configuración de routing
│   └── deployment.yaml                # Deployment + Service
│
├── prometheus-rules/
│   └── alerting-rules.yaml            # 7 reglas de alertas
│
├── grafana-dashboards/
│   ├── ecommerce-v2.json              # Dashboard técnico
│   └── ecommerce-business.json        # Dashboard de negocio
│
├── efk-stack/
│   ├── elasticsearch.yaml             # Elasticsearch deployment
│   ├── kibana.yaml                    # Kibana deployment + LB
│   └── fluentd.yaml                   # Fluentd DaemonSet
│
├── jaeger/
│   └── jaeger-all-in-one.yaml         # Jaeger deployment
│
├── docs/
│   └── screenshots/                   # Capturas de pantalla
│
└── terraform/
    ├── versions.tf
    ├── variables.tf
    ├── providers.tf
    ├── main.tf                        # Prometheus + Grafana via Helm
    ├── outputs.tf
    └── terraform.tfvars
```

---

## 🚀 Despliegue Rápido

### Desplegar Todo el Stack

```bash
cd monitoring-stack

# 1. Prometheus + Grafana con Terraform
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# 2. AlertManager
kubectl apply -f alertmanager/
kubectl apply -f prometheus-rules/

# 3. EFK Stack
kubectl apply -f efk-stack/

# 4. Jaeger
kubectl apply -f jaeger/

# 5. Importar Dashboards a Grafana
./setup-grafana.sh
```

### Verificar Despliegue

```bash
# Ver todos los pods de monitoreo
kubectl get pods -n monitoring

# Esperado:
NAME                                            READY   STATUS    
elasticsearch-xxxxx                             1/1     Running   
fluentd-xxxxx                                   1/1     Running   
grafana-xxxxx                                   1/1     Running   
jaeger-xxxxx                                    1/1     Running   
kibana-xxxxx                                    1/1     Running   
prometheus-alertmanager-0                       1/1     Running   
prometheus-server-xxxxx                         1/1     Running   
alertmanager-xxxxx                              1/1     Running   
```

---

## 🔧 Comandos Útiles

### Prometheus

```bash
# Port-forward para acceder a Prometheus UI
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

# Ver targets
curl -s localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Ver alertas activas
curl -s localhost:9090/api/v1/alerts | jq '.data.alerts'
```

### Grafana

```bash
# Listar dashboards
curl -s -u admin:admin123 "http://34.121.2.178/api/search" | jq '.[].title'

# Exportar un dashboard
curl -s -u admin:admin123 "http://34.121.2.178/api/dashboards/uid/ecommerce-v2" | jq .
```

### Jaeger

```bash
# Listar servicios
curl -s "http://104.154.243.214:16686/api/services" | jq '.data'

# Buscar trazas
curl -s "http://104.154.243.214:16686/api/traces?service=user-service&limit=10" | jq '.data | length'
```

### Elasticsearch/Kibana

```bash
# Ver índices
kubectl exec -n monitoring deploy/elasticsearch -- curl -s localhost:9200/_cat/indices?v

# Contar logs
kubectl exec -n monitoring deploy/elasticsearch -- curl -s "localhost:9200/ecommerce-logs-*/_count"

# Health del cluster
kubectl exec -n monitoring deploy/elasticsearch -- curl -s localhost:9200/_cluster/health | jq .
```

---

## 📊 Resumen de URLs

| Herramienta | URL | Propósito |
|-------------|-----|-----------|
| **Grafana** | http://34.121.2.178 | Dashboards de métricas |
| **Grafana - Dashboard Técnico** | http://34.121.2.178/d/ecommerce-v2 | Métricas JVM/HTTP |
| **Grafana - Dashboard Negocio** | http://34.121.2.178/d/ecommerce-business | Métricas de negocio |
| **Kibana** | http://34.71.123.62:5601 | Logs centralizados |
| **Jaeger** | http://104.154.243.214:16686 | Tracing distribuido |
| **AlertManager** | http://34.57.30.187:9093 | Gestión de alertas |

---

## ✅ Conclusión

Este stack de observabilidad cumple con el **100% de los requisitos del 10%** de la rúbrica:

1. ✅ **Prometheus + Grafana**: Stack completo con Helm
2. ✅ **EFK Stack**: Elasticsearch + Fluentd + Kibana para logs
3. ✅ **Dashboards**: 2 dashboards (técnico + negocio) con métricas por servicio
4. ✅ **Alertas**: 7 reglas críticas con AlertManager
5. ✅ **Tracing**: Jaeger + Spring Cloud Sleuth
6. ✅ **Health Checks**: Liveness + Readiness probes en todos los servicios
7. ✅ **Métricas de Negocio**: Órdenes, pagos, productos, usuarios, favoritos, envíos

---

**Autor**: Taller 2 - Ingeniería de Software  
**Fecha**: Noviembre 2025  
**Cluster**: GKE `ecommerce-dev-gke-v2` en `us-central1-a`
