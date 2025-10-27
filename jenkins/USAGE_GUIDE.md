# Guía de Uso del Pipeline Jenkins_Create_VM

## 🎯 **Objetivo**

Este pipeline te permite **gestionar completamente** las VMs de DigitalOcean desde Jenkins, con control total sobre cuándo crear, modificar o eliminar droplets.

## 🔧 **Parámetros del Pipeline**

### **1. ACTION (Acción a ejecutar)**
- **`status`** ⭐ **(POR DEFECTO)** - Solo consulta el estado, NO crea ni modifica nada
- **`create`** - Crea una nueva VM
- **`rebuild`** - Elimina y recrea la VM existente
- **`destroy`** - Elimina permanentemente la VM

### **2. VM_CONFIG (Configuración de VM)**
- **`standard`** - VM básica (1 CPU, 2GB RAM, ~$12/mes)
- **`ecommerce_minikube`** - VM Minikube (2 CPUs, 4GB RAM, ~$24/mes)

### **3. Otros Parámetros**
- **ARCHIVE_METADATA**: Publicar archivos de propiedades como artefactos (por defecto: `true`)
- **CONFIGURE_GCP_ACCESS**: Configurar acceso a GCP en la VM (por defecto: `true`)

### **4. Valores Automáticos por Configuración**

#### **Standard**:
- **VM_NAME**: `ecommerce-integration-runner`
- **VM_REGION**: `nyc3`
- **VM_SIZE**: `s-1vcpu-2gb`
- **VM_IMAGE**: `ubuntu-22-04-x64`
- **Costo**: `~$12/mes`

#### **ecommerce_minikube**:
- **VM_NAME**: `ecommerce-minikube-dev`
- **VM_REGION**: `nyc3`
- **VM_SIZE**: `s-2vcpu-4gb`
- **VM_IMAGE**: `ubuntu-22-04-x64`
- **Costo**: `~$24/mes`

## 🚀 **Flujo de Trabajo Recomendado**

### **Paso 1: Verificar Estado**
```
ACTION = status
VM_CONFIG = standard (o ecommerce_minikube)
VM_NAME = ecommerce-integration-runner
```
**Resultado**: Verás si la VM existe y su estado actual

### **Paso 2: Crear VM (Solo si es necesario)**
```
ACTION = create
VM_CONFIG = ecommerce_minikube
VM_NAME = ecommerce-minikube-dev
```
**Resultado**: Se creará la VM con la configuración seleccionada

### **Paso 3: Gestionar VM**
- **Para reiniciar**: `ACTION = rebuild`
- **Para eliminar**: `ACTION = destroy`
- **Para verificar**: `ACTION = status`

## ⚠️ **Importante: Evitar Creación Automática**

### **Problema Anterior**
- El pipeline tenía `ACTION = create` por defecto
- Se creaba automáticamente una VM al ejecutar

### **Solución Implementada**
- **`ACTION = status`** es ahora el valor por defecto
- Solo consulta el estado, NO crea ni modifica nada
- Debes **cambiar manualmente** a `create` cuando quieras crear una VM

## 📊 **Configuraciones Disponibles**

### **Standard (s-1vcpu-2gb)**
- **Costo**: ~$12/mes
- **Uso**: Pruebas de integración básicas
- **Herramientas**: Docker, Java 17, Git, GCP SDK

### **ecommerce_minikube (s-2vcpu-4gb)**
- **Costo**: ~$24/mes
- **Uso**: Desarrollo con Kubernetes
- **Herramientas**: Todo lo de Standard + Minikube + kubectl

## 🔄 **Ejemplos de Uso**

### **Crear VM Minikube**
```
ACTION: create
VM_CONFIG: ecommerce_minikube
VM_NAME: ecommerce-minikube-dev
```
**Resultado**: VM de 4GB RAM con Minikube preinstalado

### **Verificar Estado**
```
ACTION: status
VM_CONFIG: standard
VM_NAME: ecommerce-integration-runner
```
**Resultado**: Información sobre la VM existente

### **Eliminar VM**
```
ACTION: destroy
VM_CONFIG: ecommerce_minikube
VM_NAME: ecommerce-minikube-dev
```
**Resultado**: VM eliminada permanentemente

## 🛡️ **Seguridad y Control**

### **Advertencias Automáticas**
El pipeline ahora muestra advertencias claras:
- ⚠️ **ATENCIÓN**: Se creará una nueva VM...
- ⚠️ **ATENCIÓN**: Se eliminará la VM permanentemente...
- ℹ️ Solo se consultará el estado...

### **Información de Costos**
- Muestra el costo estimado antes de crear
- Indica claramente qué recursos se van a usar

## 📝 **Notas Importantes**

1. **Por defecto NO se crea nada** - Solo consulta estado
2. **Debes cambiar manualmente** a `create` para crear VMs
3. **Los campos se actualizan** automáticamente según la configuración
4. **Siempre verifica** el estado antes de crear/modificar
5. **Usa nombres únicos** para diferentes VMs

## 🎯 **Resumen**

- ✅ **Control total** sobre cuándo crear/modificar VMs
- ✅ **Sin creación automática** - Solo consulta por defecto
- ✅ **Configuraciones predefinidas** - Campos se actualizan automáticamente
- ✅ **Advertencias claras** - Sabes exactamente qué va a pasar
- ✅ **Gestión completa** - Crear, verificar, modificar, eliminar
