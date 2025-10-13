# Variables para el módulo Kubernetes Config

# Namespace Configuration
variable "namespace_name" {
  description = "Nombre del namespace principal"
  type        = string
  default     = "ecommerce"
}

variable "namespace_labels" {
  description = "Labels para el namespace"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Crear namespace para monitoring"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Crear namespace para logging"
  type        = bool
  default     = true
}

# ConfigMap
variable "app_config_data" {
  description = "Datos de configuración para la aplicación"
  type        = map(string)
  default = {
    "SPRING_PROFILES_ACTIVE" = "prod"
    "LOG_LEVEL"              = "INFO"
  }
}

# Database Secret
variable "create_db_secret" {
  description = "Crear secret para credenciales de base de datos"
  type        = bool
  default     = false
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  default     = ""
  sensitive   = true
}

# Docker Registry Secret
variable "create_docker_registry_secret" {
  description = "Crear secret para registry de Docker"
  type        = bool
  default     = false
}

variable "docker_registry_server" {
  description = "Servidor del registry de Docker"
  type        = string
  default     = ""
}

variable "docker_registry_username" {
  description = "Usuario del registry de Docker"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_registry_password" {
  description = "Contraseña del registry de Docker"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_registry_email" {
  description = "Email del registry de Docker"
  type        = string
  default     = ""
}

# Service Account
variable "service_account_annotations" {
  description = "Anotaciones para la service account"
  type        = map(string)
  default     = {}
}

# Resource Quotas
variable "enable_resource_quota" {
  description = "Habilitar resource quotas"
  type        = bool
  default     = false
}

variable "quota_requests_cpu" {
  description = "CPU request quota"
  type        = string
  default     = "10"
}

variable "quota_requests_memory" {
  description = "Memory request quota"
  type        = string
  default     = "20Gi"
}

variable "quota_limits_cpu" {
  description = "CPU limit quota"
  type        = string
  default     = "20"
}

variable "quota_limits_memory" {
  description = "Memory limit quota"
  type        = string
  default     = "40Gi"
}

variable "quota_pods" {
  description = "Pods quota"
  type        = string
  default     = "50"
}

# Limit Range
variable "enable_limit_range" {
  description = "Habilitar limit ranges"
  type        = bool
  default     = false
}

variable "pod_max_cpu" {
  description = "CPU máximo por pod"
  type        = string
  default     = "2"
}

variable "pod_max_memory" {
  description = "Memoria máxima por pod"
  type        = string
  default     = "4Gi"
}

variable "pod_min_cpu" {
  description = "CPU mínimo por pod"
  type        = string
  default     = "50m"
}

variable "pod_min_memory" {
  description = "Memoria mínima por pod"
  type        = string
  default     = "64Mi"
}

variable "container_default_cpu" {
  description = "CPU por defecto para containers"
  type        = string
  default     = "500m"
}

variable "container_default_memory" {
  description = "Memoria por defecto para containers"
  type        = string
  default     = "512Mi"
}

variable "container_default_request_cpu" {
  description = "CPU request por defecto para containers"
  type        = string
  default     = "250m"
}

variable "container_default_request_memory" {
  description = "Memory request por defecto para containers"
  type        = string
  default     = "256Mi"
}

variable "container_max_cpu" {
  description = "CPU máximo por container"
  type        = string
  default     = "1"
}

variable "container_max_memory" {
  description = "Memoria máxima por container"
  type        = string
  default     = "2Gi"
}

variable "container_min_cpu" {
  description = "CPU mínimo por container"
  type        = string
  default     = "50m"
}

variable "container_min_memory" {
  description = "Memoria mínima por container"
  type        = string
  default     = "64Mi"
}

# Network Policy
variable "enable_network_policy" {
  description = "Habilitar network policies"
  type        = bool
  default     = false
}

# Storage Class
variable "create_storage_class" {
  description = "Crear storage class personalizado"
  type        = bool
  default     = false
}

variable "storage_provisioner" {
  description = "Provisioner para el storage class"
  type        = string
  default     = "kubernetes.io/gce-pd"
}

variable "storage_class_parameters" {
  description = "Parámetros para el storage class"
  type        = map(string)
  default = {
    type = "pd-ssd"
  }
}

# NGINX Ingress
variable "install_nginx_ingress" {
  description = "Instalar NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "nginx_ingress_version" {
  description = "Versión de NGINX Ingress"
  type        = string
  default     = "4.8.3"
}

variable "nginx_ingress_service_type" {
  description = "Tipo de servicio para NGINX Ingress"
  type        = string
  default     = "LoadBalancer"
}

variable "nginx_ingress_resources" {
  description = "Recursos para NGINX Ingress"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

# Cert-Manager
variable "install_cert_manager" {
  description = "Instalar Cert-Manager"
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "Versión de Cert-Manager"
  type        = string
  default     = "v1.13.2"
}
