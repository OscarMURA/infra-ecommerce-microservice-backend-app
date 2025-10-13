# Variables para el módulo GKE

# Proyecto y Región
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP (solo para clusters zonales)"
  type        = string
  default     = "us-central1-a"
}

variable "regional" {
  description = "Si el cluster debe ser regional o zonal"
  type        = bool
  default     = false
}

# Cluster Configuration
variable "cluster_name" {
  description = "Nombre del cluster de GKE"
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "release_channel" {
  description = "Canal de releases (RAPID, REGULAR, STABLE)"
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

# Private Cluster Configuration
variable "enable_private_nodes" {
  description = "Habilitar nodos privados"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Habilitar endpoint privado del control plane"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR para el control plane"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "Redes autorizadas para acceder al master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

# Node Pool Configuration
variable "machine_type" {
  description = "Tipo de máquina para los nodos"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Tamaño del disco en GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Tipo de disco (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "image_type" {
  description = "Tipo de imagen del nodo (COS_CONTAINERD, UBUNTU_CONTAINERD)"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_count" {
  description = "Número de nodos (para cluster zonal)"
  type        = number
  default     = 3
}

variable "node_count_per_zone" {
  description = "Número de nodos por zona (para cluster regional)"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Número mínimo de nodos para auto-scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Número máximo de nodos para auto-scaling"
  type        = number
  default     = 5
}

variable "auto_repair" {
  description = "Habilitar reparación automática de nodos"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Habilitar actualización automática de nodos"
  type        = bool
  default     = true
}

# Critical Node Pool
variable "enable_critical_node_pool" {
  description = "Crear un node pool adicional para servicios críticos"
  type        = bool
  default     = false
}

variable "critical_machine_type" {
  description = "Tipo de máquina para nodos críticos"
  type        = string
  default     = "e2-standard-4"
}

variable "critical_disk_size_gb" {
  description = "Tamaño del disco para nodos críticos"
  type        = number
  default     = 100
}

variable "critical_node_count" {
  description = "Número de nodos críticos (zonal)"
  type        = number
  default     = 2
}

variable "critical_node_count_per_zone" {
  description = "Número de nodos críticos por zona (regional)"
  type        = number
  default     = 1
}

variable "critical_min_node_count" {
  description = "Número mínimo de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_max_node_count" {
  description = "Número máximo de nodos críticos"
  type        = number
  default     = 3
}

# Labels and Tags
variable "labels" {
  description = "Labels para el cluster"
  type        = map(string)
  default     = {}
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Tags de red para los nodos"
  type        = list(string)
  default     = ["gke-node"]
}

# Maintenance
variable "maintenance_start_time" {
  description = "Hora de inicio del mantenimiento (HH:MM)"
  type        = string
  default     = "03:00"
}

# Addons
variable "enable_http_load_balancing" {
  description = "Habilitar HTTP Load Balancing"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Habilitar Horizontal Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Habilitar Network Policy"
  type        = bool
  default     = true
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Habilitar GCE Persistent Disk CSI Driver"
  type        = bool
  default     = true
}

# Logging and Monitoring
variable "logging_components" {
  description = "Componentes de logging a habilitar"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "Componentes de monitoring a habilitar"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Habilitar Managed Prometheus"
  type        = bool
  default     = false
}

# Security
variable "enable_binary_authorization" {
  description = "Habilitar Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_secure_boot" {
  description = "Habilitar Secure Boot en los nodos"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Habilitar Integrity Monitoring en los nodos"
  type        = bool
  default     = true
}
