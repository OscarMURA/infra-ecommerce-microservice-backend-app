# KEDA - Kubernetes Event-Driven Autoscaling

## 📋 Descripción

KEDA permite el autoscaling basado en eventos y métricas externas, más allá del CPU/Memory tradicional de HPA.

## 🚀 Instalación

```bash
# Agregar repo de Helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Instalar KEDA
helm install keda kedacore/keda --namespace keda --create-namespace
```

## 📊 Triggers Implementados

### 1. Trigger basado en Prometheus (Métricas HTTP)
- **Servicio**: `order-service`
- **Métrica**: Requests por segundo
- **Escalado**: 1-10 pods cuando requests > 100/s

### 2. Trigger basado en CPU (Cron Schedule)
- **Servicio**: `product-service`  
- **Métrica**: CPU + Horario de alta demanda
- **Escalado**: Escala a 5 pods en horario pico (9am-6pm)

## 🔧 Archivos de Configuración

| Archivo | Descripción |
|---------|-------------|
| `order-service-scaledobject.yaml` | Autoscaling basado en métricas Prometheus |
| `product-service-scaledobject.yaml` | Autoscaling basado en CPU + Cron |
| `trigger-auth-prometheus.yaml` | Autenticación para Prometheus |

## 📈 Verificar Estado

```bash
# Ver ScaledObjects
kubectl get scaledobject -n prod

# Ver detalles
kubectl describe scaledobject order-service-scaler -n prod

# Ver HPAs generados por KEDA
kubectl get hpa -n prod

# Ver logs de KEDA
kubectl logs -n keda -l app=keda-operator
```

## 🧪 Probar el Autoscaling

### Test 1: Generar carga en order-service
```bash
# Instalar hey (load testing tool)
# Generar 1000 requests con 50 conexiones concurrentes
hey -n 1000 -c 50 http://<ORDER_SERVICE_IP>:8081/api/orders
```

### Test 2: Verificar escalado por horario
```bash
# El product-service debería escalar automáticamente
# durante horario pico (9am-6pm UTC)
kubectl get pods -n prod -l app=product-service -w
```

## 📉 Comportamiento Esperado

```
Carga Baja (< 50 req/s):     1 pod
Carga Media (50-100 req/s):  3 pods
Carga Alta (> 100 req/s):    5-10 pods
Horario Pico (9am-6pm):      Mínimo 3 pods
Horario Valle:               Mínimo 1 pod
```

## 🔗 Referencias

- [KEDA Documentation](https://keda.sh/docs/)
- [Prometheus Scaler](https://keda.sh/docs/scalers/prometheus/)
- [Cron Scaler](https://keda.sh/docs/scalers/cron/)
- [CPU Scaler](https://keda.sh/docs/scalers/cpu/)
