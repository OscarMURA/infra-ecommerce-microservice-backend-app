# 🚀 KEDA - Autoscaling Avanzado Basado en Eventos

## 📋 Descripción

**KEDA (Kubernetes Event-Driven Autoscaling)** es un componente que permite escalar aplicaciones en Kubernetes basándose en eventos y métricas externas, más allá del tradicional HPA basado en CPU/memoria.

## ✅ Requisitos del Taller Cumplidos

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| Implementar KEDA para autoscaling basado en eventos | ✅ | Instalado via Helm |
| Configurar al menos dos triggers diferentes | ✅ | 4 triggers configurados |
| Demostrar y documentar el comportamiento | ✅ | Este documento |

---

## 🛠️ Instalación

### Comando de instalación
```bash
# Agregar repositorio de Helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Instalar KEDA en el namespace 'keda'
helm install keda kedacore/keda --namespace keda --create-namespace
```

### Verificar instalación
```bash
kubectl get pods -n keda
```

Resultado esperado:
```
NAME                                               READY   STATUS    RESTARTS   AGE
keda-admission-webhooks-xxx                        1/1     Running   0          5m
keda-operator-xxx                                  1/1     Running   0          5m
keda-operator-metrics-apiserver-xxx                1/1     Running   0          5m
```

---

## 📊 Triggers Implementados

### Arquitectura de Autoscaling

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         KEDA AUTOSCALING                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌──────────────────────────────────────────┐  │
│  │   PROMETHEUS    │────▶│  order-service-scaler                    │  │
│  │   (Trigger 1)   │     │  • Métrica: HTTP requests/segundo        │  │
│  │                 │     │  • Threshold: 50 req/s                   │  │
│  └─────────────────┘     │  • Scale: 1-10 pods                      │  │
│                          └──────────────────────────────────────────┘  │
│                                                                         │
│  ┌─────────────────┐     ┌──────────────────────────────────────────┐  │
│  │      CPU        │────▶│  product-service-scaler                  │  │
│  │   (Trigger 2)   │     │  • Métrica: CPU Utilization > 70%        │  │
│  └─────────────────┘     │  • Scale: 1-8 pods                       │  │
│                          └──────────────────────────────────────────┘  │
│                                                                         │
│  ┌─────────────────┐     ┌──────────────────────────────────────────┐  │
│  │      CRON       │────▶│  product-service-scaler                  │  │
│  │   (Trigger 3)   │     │  • Horario pico: 9am-6pm (Lun-Vie)       │  │
│  │                 │     │  • Desired: 3 pods en horario pico       │  │
│  └─────────────────┘     └──────────────────────────────────────────┘  │
│                                                                         │
│  ┌─────────────────┐     ┌──────────────────────────────────────────┐  │
│  │     MEMORY      │────▶│  user-service-scaler                     │  │
│  │   (Trigger 4)   │     │  • Métrica: Memory Utilization > 75%     │  │
│  │                 │     │  • Scale: 1-6 pods                       │  │
│  └─────────────────┘     └──────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Archivos de Configuración

### Ubicación
```
infra-ecommerce-microservice-backend-app/kubernetes/keda/
├── README.md                           # Documentación técnica
├── trigger-auth-prometheus.yaml        # Autenticación para Prometheus
├── order-service-scaledobject.yaml     # ScaledObject con trigger Prometheus
└── product-service-scaledobject.yaml   # ScaledObject con triggers CPU + Cron + Memory
```

---

## 🔧 Configuración Detallada

### 1️⃣ Trigger Prometheus (order-service)

**Archivo:** `order-service-scaledobject.yaml`

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-service-scaler
  namespace: prod
spec:
  scaleTargetRef:
    name: order-service
  minReplicaCount: 1
  maxReplicaCount: 10
  pollingInterval: 15      # Verifica cada 15 segundos
  cooldownPeriod: 60       # Espera 60s antes de reducir
  
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-server.monitoring.svc.cluster.local:80
        query: |
          sum(rate(http_server_requests_seconds_count{application="order-service"}[2m]))
        threshold: "50"    # Escala cuando > 50 req/s
```

**Comportamiento:**
- 🟢 < 50 req/s → 1 pod
- 🟡 50-100 req/s → 2-5 pods
- 🔴 > 100 req/s → 5-10 pods

---

### 2️⃣ Trigger CPU + Cron (product-service)

**Archivo:** `product-service-scaledobject.yaml`

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: product-service-scaler
  namespace: prod
spec:
  scaleTargetRef:
    name: product-service
  minReplicaCount: 1
  maxReplicaCount: 8
  
  triggers:
    # Trigger CPU
    - type: cpu
      metricType: Utilization
      metadata:
        value: "70"        # Escala cuando CPU > 70%
    
    # Trigger Cron (horario pico)
    - type: cron
      metadata:
        timezone: America/Bogota
        start: "0 9 * * 1-5"     # Lunes-Viernes 9:00 AM
        end: "0 18 * * 1-5"      # Lunes-Viernes 6:00 PM
        desiredReplicas: "3"     # Mínimo 3 pods en horario pico
```

**Comportamiento:**
| Horario | CPU < 70% | CPU > 70% |
|---------|-----------|-----------|
| 9am-6pm (Lun-Vie) | 3 pods | 3-8 pods |
| Fuera de horario | 1 pod | 1-8 pods |

---

### 3️⃣ Trigger Memory + CPU (user-service)

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: user-service-scaler
  namespace: prod
spec:
  scaleTargetRef:
    name: user-service
  minReplicaCount: 1
  maxReplicaCount: 6
  
  triggers:
    - type: memory
      metricType: Utilization
      metadata:
        value: "75"        # Escala cuando memoria > 75%
    
    - type: cpu
      metricType: Utilization
      metadata:
        value: "80"        # Escala cuando CPU > 80%
```

---

## 🧪 Verificación y Pruebas

### Verificar ScaledObjects
```bash
kubectl get scaledobject -n prod
```

**Resultado:**
```
NAME                     SCALETARGETKIND   SCALETARGETNAME   MIN   MAX   TRIGGERS
order-service-scaler                       order-service     1     10    prometheus
product-service-scaler                     product-service   1     8     cpu,cron
user-service-scaler                        user-service      1     6     memory,cpu
```

### Ver HPAs generados por KEDA
```bash
kubectl get hpa -n prod
```

### Ver detalles de un ScaledObject
```bash
kubectl describe scaledobject order-service-scaler -n prod
```

### Ver logs de KEDA
```bash
kubectl logs -n keda -l app=keda-operator --tail=50
```

---

## 📈 Prueba de Carga (Demostración)

### Generar carga para probar autoscaling
```bash
# Instalar hey (herramienta de load testing)
# En Fedora/RHEL:
go install github.com/rakyll/hey@latest

# Generar 5000 requests con 100 conexiones concurrentes
hey -n 5000 -c 100 http://<ORDER_SERVICE_IP>:8081/api/orders

# Observar el escalado en tiempo real
kubectl get pods -n prod -l app=order-service -w
```

### Observar comportamiento
```bash
# Ver eventos de escalado
kubectl get events -n prod --sort-by='.lastTimestamp' | grep -i scale

# Ver métricas del HPA
kubectl get hpa -n prod -w
```

---

## 📊 Comportamiento Esperado

### Escenario 1: Carga Normal (< 50 req/s)
```
order-service:   1 pod  ✓
product-service: 1 pod  ✓ (fuera de horario pico)
user-service:    1 pod  ✓
```

### Escenario 2: Alta Carga (> 100 req/s)
```
order-service:   5-10 pods ↑ (escalado por Prometheus)
product-service: 1-8 pods  ↑ (si CPU > 70%)
user-service:    1-6 pods  ↑ (si memoria > 75%)
```

### Escenario 3: Horario Pico (9am-6pm)
```
product-service: Mínimo 3 pods (garantizado por cron trigger)
```

---

## 🔄 Diferencias con HPA Tradicional

| Característica | HPA Tradicional | KEDA |
|---------------|-----------------|------|
| Métricas | CPU, Memoria | Cualquier fuente (Prometheus, Kafka, RabbitMQ, Cron, etc.) |
| Scale to Zero | ❌ No | ✅ Sí |
| Triggers externos | ❌ No | ✅ Sí |
| Eventos | ❌ No | ✅ Sí |
| Múltiples triggers | ❌ No | ✅ Sí |

---

## 🎯 Beneficios Implementados

1. **Autoscaling Inteligente**: Escala basándose en métricas de negocio (requests) no solo recursos
2. **Ahorro de Costos**: Scale to zero cuando no hay tráfico
3. **Preparación para Picos**: Cron trigger pre-escala antes del horario pico
4. **Multi-trigger**: Combina CPU + Cron + Memory para decisiones más inteligentes
5. **Integración con Prometheus**: Usa las métricas existentes del stack de monitoreo

---

## 📚 Referencias

- [KEDA Documentation](https://keda.sh/docs/)
- [Prometheus Scaler](https://keda.sh/docs/scalers/prometheus/)
- [Cron Scaler](https://keda.sh/docs/scalers/cron/)
- [CPU Scaler](https://keda.sh/docs/scalers/cpu/)
- [Memory Scaler](https://keda.sh/docs/scalers/memory/)

---

## 👥 Autores

- Equipo de DevOps - Taller 2 Ingeniería de Software
- Universidad Icesi - 2025
