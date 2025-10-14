# Variables para ambiente dev - GKE

# GCP Configuration
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "credentials_file" {
  description = "Ruta al archivo de credenciales de GCP"
  type        = string
  default     = ""
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP"
  type        = string
  default     = "us-central1-a"
}

variable "regional" {
  description = "Cluster regional o zonal"
  type        = bool
  default     = false
}

# Cluster Configuration
variable "cluster_name" {
  description = "Nombre del cluster"
  type        = string
  default     = "ecommerce-dev-gke-v2"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.32.9-gke.1108000"
}

variable "release_channel" {
  description = "Canal de releases"
  type        = string
  default     = "REGULAR"
}

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR para la subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR para los pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "CIDR para los servicios"
  type        = string
  default     = "10.8.0.0/20"
}

# Private Cluster
variable "enable_private_nodes" {
  description = "Habilitar nodos privados"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Habilitar endpoint privado"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR del control plane"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "Redes autorizadas"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

# Node Pool
variable "machine_type" {
  description = "Tipo de máquina"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Tamaño del disco"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Tipo de disco"
  type        = string
  default     = "pd-balanced"
}

variable "image_type" {
  description = "Tipo de imagen"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_count" {
  description = "Número de nodos (zonal)"
  type        = number
  default     = 2
}

variable "node_count_per_zone" {
  description = "Nodos por zona (regional)"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Mínimo de nodos"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Máximo de nodos"
  type        = number
  default     = 3
}

variable "auto_repair" {
  description = "Auto-reparación"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Auto-actualización"
  type        = bool
  default     = true
}

# Labels y Tags
variable "labels" {
  description = "Labels del cluster"
  type        = map(string)
  default     = {}
}

variable "node_labels" {
  description = "Labels de los nodos"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Tags de red"
  type        = list(string)
  default     = ["gke-node", "ecommerce"]
}

# Critical Node Pool
variable "enable_critical_node_pool" {
  description = "Crear node pool crítico"
  type        = bool
  default     = false
}

variable "critical_machine_type" {
  description = "Tipo de máquina crítica"
  type        = string
  default     = "e2-standard-4"
}

variable "critical_disk_size_gb" {
  description = "Disco para nodos críticos"
  type        = number
  default     = 100
}

variable "critical_node_count" {
  description = "Número de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_node_count_per_zone" {
  description = "Nodos críticos por zona"
  type        = number
  default     = 1
}

variable "critical_min_node_count" {
  description = "Mínimo de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_max_node_count" {
  description = "Máximo de nodos críticos"
  type        = number
  default     = 2
}

# Maintenance
variable "maintenance_start_time" {
  description = "Hora de mantenimiento"
  type        = string
  default     = "03:00"
}

# Addons
variable "enable_http_load_balancing" {
  description = "HTTP Load Balancing"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "HPA"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Network Policy"
  type        = bool
  default     = true
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "CSI Driver"
  type        = bool
  default     = true
}

# Logging y Monitoring
variable "logging_components" {
  description = "Componentes de logging"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "Componentes de monitoring"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Managed Prometheus"
  type        = bool
  default     = false
}

# Security
variable "enable_binary_authorization" {
  description = "Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_secure_boot" {
  description = "Secure Boot"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Integrity Monitoring"
  type        = bool
  default     = true
}
