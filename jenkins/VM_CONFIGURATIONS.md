# Configuraciones de VM en Jenkins_Create_VM

## 📋 Resumen

El pipeline `Jenkins_Create_VM` ahora soporta múltiples configuraciones predefinidas de VM a través del parámetro `VM_CONFIG`. Cada configuración está optimizada para diferentes casos de uso.

## 🔧 Configuraciones Disponibles

### 1. **standard** (Configuración por defecto)
- **Tamaño**: `s-2vcpu-4gb` (2 CPU, 4GB RAM)
- **Costo**: ~$24/mes
- **Uso**: Pruebas de integración básicas
- **Herramientas incluidas**:
  - Docker + Docker Compose
  - Java 17
  - Git, curl, jq
  - Google Cloud SDK
  - Python 3

### 2. **ecommerce_minikube** (Nueva configuración)
- **Tamaño**: `s-4vcpu-8gb` (4 CPUs, 8GB RAM)
- **Costo**: ~$48/mes
- **Uso**: Desarrollo y pruebas con Kubernetes local
- **Herramientas incluidas**:
  - Todo lo de la configuración `standard`
  - Minikube preinstalado y configurado
  - kubectl configurado
  - Herramientas adicionales para Kubernetes
  - Script de utilidades para Minikube

## 🚀 Características de la VM Minikube

### Recursos Optimizados
- **RAM total**: 8GB
- **RAM para Minikube**: 6GB (dejando 2GB para el sistema)
- **CPUs**: 4 cores completos
- **Disco**: 80GB SSD (20GB asignados a Minikube)

### Configuración de Minikube
```bash
# Configuración automática
minikube start --driver=docker --memory=6144 --cpus=4 --disk-size=20g
```

### Utilidades Incluidas
- Script `minikube-utils.sh` con comandos útiles:
  ```bash
  ./minikube-utils.sh status     # Estado de Minikube
  ./minikube-utils.sh dashboard  # Abrir dashboard
  ./minikube-utils.sh services   # Listar servicios
  ./minikube-utils.sh logs <pod> # Ver logs de un pod
  ./minikube-utils.sh restart    # Reiniciar Minikube
  ```

### Acceso desde Jenkins Server
- SSH habilitado con autenticación por contraseña
- Usuario: `jenkins`
- Puertos abiertos: 22, 3000, 8000, 8080-8083, 8443, 30000-32767

## 📊 Comparación de Configuraciones

| Característica | standard | ecommerce_minikube |
|----------------|----------|-------------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 4GB | 8GB |
| **Costo/mes** | ~$24 | ~$48 |
| **Docker** | ✅ | ✅ |
| **Minikube** | ❌ | ✅ |
| **kubectl** | ❌ | ✅ |
| **Kubernetes Dashboard** | ❌ | ✅ |
| **Herramientas K8s** | ❌ | ✅ |

## 🔄 Flujo de Creación

### Para configuración `standard`:
1. Crear VM con cloud-init básico
2. Instalar Docker y herramientas
3. Configurar GCP access (opcional)
4. VM lista para pruebas

### Para configuración `ecommerce_minikube`:
1. Crear VM con cloud-init específico para Minikube
2. Instalar Docker, Minikube y kubectl
3. Configurar Minikube automáticamente
4. Configurar GCP access (opcional)
5. VM lista para desarrollo con Kubernetes

## 🎯 Casos de Uso Recomendados

### Usar `standard` cuando:
- Ejecutar pruebas unitarias e integración
- Desarrollar microservicios individuales
- Pruebas de CI/CD básicas
- Presupuesto limitado

### Usar `ecommerce_minikube` cuando:
- Desarrollar aplicaciones Kubernetes
- Probar despliegues completos localmente
- Debugging de aplicaciones distribuidas
- Simular entornos de producción
- Desarrollo de Helm charts

## 🔧 Configuración en Jenkins

### Parámetros del Pipeline:
- `VM_CONFIG`: Seleccionar entre `standard` o `ecommerce_minikube`
- `VM_NAME`: Nombre de la VM (se ajusta automáticamente según configuración)
- `VM_REGION`: Región de DigitalOcean
- `VM_SIZE`: Se sobrescribe automáticamente según `VM_CONFIG`

### Ejemplo de uso:
```groovy
// Crear VM estándar
VM_CONFIG = 'standard'
VM_NAME = 'ecommerce-integration-runner'

// Crear VM para Minikube
VM_CONFIG = 'ecommerce_minikube'
VM_NAME = 'ecommerce-minikube-dev'
```

## 📝 Notas Importantes

1. **Costo**: La configuración Minikube cuesta el doble que la estándar
2. **Tiempo de creación**: La VM Minikube toma más tiempo en inicializarse
3. **Recursos**: Minikube está configurado con 6GB de RAM y 4 CPUs para mejor rendimiento
4. **Acceso**: Ambas VMs son accesibles desde el Jenkins Server usando SSH
5. **Persistencia**: Los datos de Minikube se mantienen entre reinicios de la VM

## 🚨 Troubleshooting

### Si Minikube no inicia:
```bash
# En la VM, ejecutar:
minikube delete
minikube start --driver=docker --memory=6144 --cpus=4
```

### Si hay problemas de memoria:
```bash
# Verificar recursos disponibles:
free -h
docker system df
```

### Si kubectl no funciona:
```bash
# Reconfigurar contexto:
minikube kubectl -- get nodes
```
