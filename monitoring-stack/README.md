# 📊 Stack de Observabilidad y Monitoreo - E-Commerce Microservices

> **Taller 2 - Ingeniería de Software**  
> Implementación completa del 10% correspondiente a **Observabilidad y Monitoreo**

---

## ✅ Estado Actual del Despliegue

Stack completo de observabilidad para los microservicios de E-Commerce desplegado en **Google Kubernetes Engine (GKE)** usando Terraform, Helm y manifests de Kubernetes.

| Componente | Estado | Tipo | Notas |
|------------|--------|------|-------|
| **Grafana** | ✅ Running | LoadBalancer | Dashboards y visualización |
| **Prometheus Server** | ✅ Running | ClusterIP | Recolección de métricas |
| **AlertManager** | ✅ Running | LoadBalancer | Gestión de alertas |
| **Node Exporter** | ✅ Running | ClusterIP | Métricas de nodos |
| **Elasticsearch** | ✅ Running | ClusterIP | Almacenamiento de logs |
| **Kibana** | ✅ Running | LoadBalancer | Visualización de logs |
| **Fluentd** | ✅ Running | DaemonSet | Recolección de logs |
| **Jaeger** | ✅ Running | LoadBalancer | Tracing distribuido |

---

## 📋 Checklist de Requisitos (10% - Observabilidad y Monitoreo)

| # | Requisito | Estado | Implementación |
|---|-----------|--------|----------------|
| 1 | Implementar stack de monitoreo con Prometheus y Grafana | ✅ | Helm charts + Terraform |
| 2 | Configurar ELK Stack para gestión de logs | ✅ | EFK (Elasticsearch + Fluentd + Kibana) |
| 3 | Implementar dashboards relevantes para cada servicio | ✅ | 2 dashboards (técnico + negocio) |
| 4 | Configurar alertas para situaciones críticas | ✅ | 7 reglas de alertas + AlertManager |
| 5 | Implementar tracing distribuido | ✅ | Jaeger + Spring Cloud Sleuth |
| 6 | Configurar health checks y readiness/liveness probes | ✅ | Actuator + K8s probes |
| 7 | Implementar métricas de negocio además de técnicas | ✅ | Dashboard de Business Metrics |

---

## 🌐 URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Grafana** | http://34.121.2.178 | admin / admin123 |
| **AlertManager** | http://34.57.30.187:9093 | N/A |
| **Kibana** | http://34.71.123.62:5601 | N/A |
| **Jaeger** | http://104.154.243.214:16686 | N/A |
| **Prometheus** | Port-forward → localhost:9090 | N/A |

---

## 🏗️ Arquitectura de Observabilidad

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY STACK                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│   MÉTRICAS    │          │     LOGS      │          │    TRACING    │
│  (Prometheus) │          │  (EFK Stack)  │          │   (Jaeger)    │
└───────┬───────┘          └───────┬───────┘          └───────┬───────┘
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│   Grafana     │          │    Kibana     │          │   Jaeger UI   │
│  Dashboards   │          │   Log Search  │          │ Trace Viewer  │
└───────────────┘          └───────────────┘          └───────────────┘
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │       MICROSERVICIOS        │
                    │  user, product, order,      │
                    │  payment, shipping,         │
                    │  favourite, service-disc    │
                    └─────────────────────────────┘
```

---

## 1️⃣ Stack de Monitoreo: Prometheus + Grafana

### Componentes Desplegados

| Componente | Versión | Estado | Tipo de Servicio |
|------------|---------|--------|------------------|
| Prometheus Server | v2.48.0 | ✅ Running | ClusterIP |
| Grafana | 10.2.0 | ✅ Running | LoadBalancer |
| Node Exporter | v1.7.0 | ✅ Running | ClusterIP |
| AlertManager | v0.26.0 | ✅ Running | LoadBalancer |

### Anotaciones en Pods para Scraping

Todos los microservicios tienen las siguientes anotaciones:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

---

## 2️⃣ EFK Stack: Gestión de Logs

### Arquitectura EFK

```
┌─────────────────────────────────────────────────────────────┐
│                        EFK STACK                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────┐       ┌───────────────┐       ┌─────────┐     │
│   │ Fluentd │──────▶│ Elasticsearch │◀──────│ Kibana  │     │
│   │(DaemonSet)      │   (Storage)   │       │  (UI)   │     │
│   └─────────┘       └───────────────┘       └─────────┘     │
│        ▲                                                     │
│        │                                                     │
│   Container Logs                                             │
│   /var/log/containers/*.log                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Componentes

| Componente | Versión | Imagen Docker | Función |
|------------|---------|---------------|---------|
| Elasticsearch | 7.17.16 | `elasticsearch:7.17.16` | Almacenamiento de logs |
| Fluentd | 1.16 | `fluent/fluentd-kubernetes-daemonset` | Recolección de logs |
| Kibana | 7.17.16 | `kibana:7.17.16` | Visualización de logs |

### Índices de Logs

Los logs se almacenan en índices diarios:
```
ecommerce-logs-2025.11.30
ecommerce-logs-2025.11.29
...
```

### Configurar Kibana (Data View)

1. Acceder a **Kibana**: http://34.71.123.62:5601
2. Ir a **Stack Management** → **Data Views**
3. Crear nuevo Data View:
   - **Name**: `ecommerce-logs`
   - **Index pattern**: `ecommerce-logs-*`
   - **Time field**: `@timestamp`
4. Ir a **Discover** para explorar logs

---

## 3️⃣ Dashboards de Grafana

### Dashboard 1: E-Commerce Microservices v2 (Técnico)

**URL**: http://34.121.2.178/d/ecommerce-v2/e-commerce-microservices-v2

| Panel | Métricas | Descripción |
|-------|----------|-------------|
| Service Status | `up{job="ecommerce-prod"}` | Estado UP/DOWN de cada servicio |
| HTTP Request Rate | `rate(http_server_requests_seconds_count[5m])` | Requests por segundo |
| HTTP Response Time | `histogram_quantile(0.95, ...)` | Latencia P95 |
| JVM Heap Memory | `jvm_memory_used_bytes{area="heap"}` | Uso de memoria heap |
| JVM Threads | `jvm_threads_live_threads` | Threads activos |
| System CPU | `process_cpu_usage` | Uso de CPU por servicio |
| HikariCP Connections | `hikaricp_connections_active` | Pool de conexiones DB |

### Dashboard 2: E-Commerce Business Metrics (Negocio)

**URL**: http://34.121.2.178/d/ecommerce-business/e-commerce-business-metrics

| Panel | Métrica | Descripción |
|-------|---------|-------------|
| Órdenes por Segundo | `rate(http_server_requests_seconds_count{uri="/api/orders",method="POST"}[5m])` | Nuevas órdenes |
| Pagos por Segundo | `rate(http_server_requests_seconds_count{uri=~"/api/payments.*",method="POST"}[5m])` | Pagos procesados |
| Consultas de Productos | `rate(http_server_requests_seconds_count{uri="/api/products",method="GET"}[5m])` | Búsquedas |
| Tasa de Errores Global | `sum(rate(...{status=~"5.."}[5m])) / sum(rate(...[5m]))` | % errores HTTP 5xx |

---

## 4️⃣ Sistema de Alertas

### Alertas Configuradas

| Alerta | Condición | Severidad | Descripción |
|--------|-----------|-----------|-------------|
| `ServiceDown` | Servicio no responde por 1min | 🔴 critical | Un microservicio está caído |
| `PodRestarting` | >3 reinicios en 15min | 🟡 warning | Pod reiniciándose frecuentemente |
| `HighLatency` | P95 > 2s por 5min | 🟡 warning | Alta latencia en respuestas |
| `HighErrorRate` | Errores > 5% por 5min | 🔴 critical | Alta tasa de errores HTTP 5xx |
| `HighMemoryUsage` | Heap > 80% por 5min | 🟡 warning | Alto uso de memoria JVM |
| `HighCpuUsage` | CPU > 80% por 10min | 🟡 warning | Alto uso de CPU |
| `DBPoolExhausted` | Pool DB > 80% | 🟡 warning | Pool de conexiones casi lleno |

### Arquitectura de Alertas

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Prometheus │────▶│ AlertManager │────▶│  Receptores  │
│   (reglas)  │     │  (routing)   │     │  (webhook)   │
└─────────────┘     └──────────────┘     └──────────────┘
```

### Simular una Alerta (Testing)

```bash
# Escalar payment-service a 0 para disparar ServiceDown
kubectl scale deployment/payment-service -n prod --replicas=0

# Esperar 1-2 minutos y verificar en AlertManager:
# http://34.57.30.187:9093/#/alerts

# Restaurar el servicio
kubectl scale deployment/payment-service -n prod --replicas=1
```

---

## 5️⃣ Tracing Distribuido con Jaeger

### Arquitectura de Tracing

```
┌─────────────────────────────────────────────────────────────┐
│                    DISTRIBUTED TRACING                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────────┐              ┌─────────────────┐      │
│   │  Microservicio  │              │     Jaeger      │      │
│   │  ┌───────────┐  │   HTTP POST  │  ┌───────────┐  │      │
│   │  │  Sleuth   │──┼─────────────▶│  │ Collector │  │      │
│   │  │  Zipkin   │  │ /api/v2/spans│  │  :9411    │  │      │
│   │  │ Reporter  │  │              │  └─────┬─────┘  │      │
│   │  └───────────┘  │              │        │        │      │
│   └─────────────────┘              │        ▼        │      │
│                                    │  ┌───────────┐  │      │
│   Genera:                          │  │  Storage  │  │      │
│   - Trace ID                       │  │ (Memory)  │  │      │
│   - Span ID                        │  └─────┬─────┘  │      │
│   - Parent Span ID                 │        │        │      │
│   - Timestamps                     │        ▼        │      │
│   - Tags                           │  ┌───────────┐  │      │
│                                    │  │ Jaeger UI │  │      │
│                                    │  │  :16686   │  │      │
│                                    │  └───────────┘  │      │
│                                    └─────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Configuración en Microservicios

Cada microservicio tiene en su `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

Y en `application.yml`:

```yaml
spring:
  application:
    name: user-service  # Nombre único por servicio
  sleuth:
    sampler:
      probability: 1.0
  zipkin:
    base-url: http://jaeger-collector.monitoring.svc.cluster.local:9411
```

### Servicios con Tracing Habilitado

| Servicio | spring.application.name | Estado |
|----------|------------------------|--------|
| user-service | `user-service` | ✅ Enviando trazas |
| product-service | `product-service` | ✅ Enviando trazas |
| order-service | `order-service` | ✅ Enviando trazas |
| payment-service | `payment-service` | ✅ Enviando trazas |
| shipping-service | `shipping-service` | ✅ Enviando trazas |
| favourite-service | `favourite-service` | ✅ Enviando trazas |
| service-discovery | `service-discovery` | ✅ Enviando trazas |

### Usar Jaeger UI

1. Acceder a: http://104.154.243.214:16686
2. Seleccionar un servicio en el dropdown "Service"
3. Click en "Find Traces"
4. Click en una traza para ver el timeline completo

---

## 6️⃣ Health Checks y Probes

### Configuración de Probes en Kubernetes

Todos los deployments tienen configurados:

```yaml
spec:
  containers:
    - name: service
      livenessProbe:
        httpGet:
          path: /actuator/health/liveness
          port: 8080
        initialDelaySeconds: 60
        periodSeconds: 10
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /actuator/health/readiness
          port: 8080
        initialDelaySeconds: 30
        periodSeconds: 5
        failureThreshold: 3
```

### Endpoints de Health

| Endpoint | Propósito |
|----------|-----------|
| `/actuator/health` | Estado general del servicio |
| `/actuator/health/liveness` | ¿El servicio está vivo? |
| `/actuator/health/readiness` | ¿El servicio puede recibir tráfico? |
| `/actuator/prometheus` | Métricas para Prometheus |

---

## 7️⃣ Métricas de Negocio

### Métricas Implementadas

| Métrica | Tipo | Descripción |
|---------|------|-------------|
| Órdenes creadas/s | Rate | Nuevas órdenes por segundo |
| Pagos procesados/s | Rate | Pagos exitosos por segundo |
| Productos consultados/s | Rate | Búsquedas de productos |
| Usuarios activos/s | Rate | Actividad de usuarios |
| Favoritos agregados/s | Rate | Items agregados a favoritos |
| Envíos procesados/s | Rate | Órdenes enviadas |
| Tasa de errores | Percentage | % de requests con error 5xx |
| Latencia P95 | Histogram | Tiempo de respuesta percentil 95 |

---

## 📁 Estructura del Directorio

```
monitoring-stack/
├── README.md                        # Esta documentación
├── deploy.sh                        # Script de despliegue completo
├── deploy-efk.sh                    # Script para EFK Stack
├── deploy-alerting.sh               # Script para alertas
├── setup-grafana.sh                 # Configuración de Grafana
│
├── alertmanager/
│   ├── configmap.yaml               # Configuración de AlertManager
│   └── deployment.yaml              # Deployment y Service
│
├── prometheus-rules/
│   └── alerting-rules.yaml          # Reglas de alertas
│
├── grafana-dashboards/
│   ├── ecommerce-v2.json            # Dashboard técnico
│   └── ecommerce-business.json      # Dashboard de negocio
│
├── efk-stack/
│   ├── elasticsearch.yaml           # Elasticsearch Deployment
│   ├── kibana.yaml                  # Kibana Deployment
│   └── fluentd.yaml                 # Fluentd DaemonSet
│
└── terraform/
    ├── main.tf                      # Recursos Helm (Prometheus + Grafana)
    ├── variables.tf                 # Variables configurables
    └── providers.tf                 # Conexión a GCP/GKE
```

---

## 🔧 Comandos Útiles

### Ver estado del stack

```bash
# Ver pods del stack de monitoreo
kubectl get pods -n monitoring

# Ver servicios y sus IPs
kubectl get svc -n monitoring

# Ver logs de un componente
kubectl logs -l app.kubernetes.io/name=grafana -n monitoring
kubectl logs -l app.kubernetes.io/name=prometheus -n monitoring -c prometheus-server
kubectl logs -l app=alertmanager -n monitoring
kubectl logs -l app=fluentd -n monitoring --tail=50
```

### Port-forward para acceso local

```bash
# Prometheus
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

# AlertManager (si no tiene LoadBalancer)
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring
```

### Verificar alertas

```bash
# Ver alertas activas en Prometheus
kubectl exec -n monitoring deployment/prometheus-server -- \
  wget -qO- "http://localhost:9090/api/v1/alerts" | jq '.data.alerts'

# Ver reglas de alertas cargadas
kubectl exec -n monitoring deployment/prometheus-server -- \
  wget -qO- "http://localhost:9090/api/v1/rules" | jq '.data.groups[].name'
```

### Verificar EFK

```bash
# Ver índices en Elasticsearch
kubectl exec -n monitoring deploy/elasticsearch -- \
  curl -s localhost:9200/_cat/indices?v

# Contar documentos
kubectl exec -n monitoring deploy/elasticsearch -- \
  curl -s "localhost:9200/ecommerce-logs-*/_count" | jq .count
```

---

## 🚀 Despliegue Rápido

### Desplegar todo el stack

```bash
cd monitoring-stack/terraform

# Inicializar y aplicar Terraform
terraform init
terraform apply -auto-approve

# Desplegar componentes adicionales
cd ..
./deploy-efk.sh
./deploy-alerting.sh
```

### Destruir el stack

```bash
cd monitoring-stack/terraform
terraform destroy -auto-approve

# Eliminar recursos manuales
kubectl delete -f alertmanager/
kubectl delete -f prometheus-rules/
kubectl delete -f efk-stack/
```

---

## 📚 Referencias

- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Spring Cloud Sleuth](https://spring.io/projects/spring-cloud-sleuth)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
