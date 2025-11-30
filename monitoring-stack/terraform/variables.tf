# ============================================
# Variables para conectarse a GCP/GKE existente
# ============================================

variable "project_id" {
  description = "ID del proyecto en GCP"
  type        = string
  default     = "devops-activity"
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP donde está el cluster"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Nombre del cluster GKE existente"
  type        = string
  default     = "ecommerce-dev-gke-v2"
}

# ============================================
# Variables de Monitoring Stack
# ============================================

variable "monitoring_namespace" {
  description = "Namespace para Prometheus y Grafana"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Contraseña del admin de Grafana"
  type        = string
  sensitive   = true
  default     = "admin123"  # CAMBIAR en producción
}

variable "prometheus_retention" {
  description = "Tiempo de retención de métricas en Prometheus"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Tamaño del storage para Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Tamaño del storage para Grafana"
  type        = string
  default     = "5Gi"
}

# ============================================
# Variables de exposición de servicios
# ============================================

variable "expose_grafana" {
  description = "Exponer Grafana con LoadBalancer (true) o ClusterIP (false)"
  type        = bool
  default     = true
}

variable "expose_prometheus" {
  description = "Exponer Prometheus con LoadBalancer (true) o ClusterIP (false)"
  type        = bool
  default     = false  # Por seguridad, solo acceso interno
}

# ============================================
# Namespaces a monitorear
# ============================================

variable "namespaces_to_monitor" {
  description = "Lista de namespaces donde están los microservicios"
  type        = list(string)
  default     = ["prod", "staging", "default"]
}
