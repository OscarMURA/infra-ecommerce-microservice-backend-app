# Variables para ambiente dev - DOKS

# DigitalOcean Token
variable "do_token" {
  description = "Token de DigitalOcean"
  type        = string
  sensitive   = true
}

# Cluster Configuration
variable "cluster_name" {
  description = "Nombre del cluster"
  type        = string
  default     = "ecommerce-dev-doks"
}

variable "region" {
  description = "Región de DigitalOcean"
  type        = string
  default     = "nyc1"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.30.2-do.0"  # Versión actualizada y estable
}

variable "vpc_ip_range" {
  description = "Rango de IPs para la VPC"
  type        = string
  default     = "10.116.0.0/16"  # Rango seguro y válido para DOKS
}

# Node Pool
variable "node_size" {
  description = "Tamaño de los nodos"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Número de nodos"
  type        = number
  default     = 2
}

variable "enable_auto_scaling" {
  description = "Habilitar auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Número máximo de nodos"
  type        = number
  default     = 3
}

# Tags y Labels
variable "tags" {
  description = "Tags para los recursos"
  type        = list(string)
  default     = ["ecommerce", "microservices"]
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default     = {}
}

# Maintenance
variable "maintenance_day" {
  description = "Día de mantenimiento"
  type        = string
  default     = "sunday"
}

variable "maintenance_start_time" {
  description = "Hora de inicio del mantenimiento"
  type        = string
  default     = "04:00"
}

# Critical Node Pool
variable "enable_critical_node_pool" {
  description = "Crear node pool crítico"
  type        = bool
  default     = false
}

variable "critical_node_size" {
  description = "Tamaño de nodos críticos"
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "critical_node_count" {
  description = "Número de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_min_nodes" {
  description = "Mínimo de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_max_nodes" {
  description = "Máximo de nodos críticos"
  type        = number
  default     = 2
}

# Firewall
variable "enable_firewall" {
  description = "Habilitar firewall"
  type        = bool
  default     = true
}

# Container Registry
variable "enable_container_registry" {
  description = "Crear container registry"
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Nombre del registry"
  type        = string
  default     = "ecommerce-dev-registry"
}

variable "registry_tier" {
  description = "Tier del registry"
  type        = string
  default     = "starter"
}

variable "registry_region" {
  description = "Región del registry"
  type        = string
  default     = "nyc3"
}

# Kubeconfig
variable "save_kubeconfig" {
  description = "Guardar kubeconfig localmente"
  type        = bool
  default     = false
}
