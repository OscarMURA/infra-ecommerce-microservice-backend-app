# Variables para el módulo AKS

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
}

variable "location" {
  description = "Región de Azure (ej: eastus, westeurope)"
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el cluster"
  type        = string
}

# Network Configuration
variable "vnet_address_space" {
  description = "CIDR de la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "CIDR de la subnet para AKS"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "network_plugin" {
  description = "Plugin de red (azure o kubenet)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR para servicios de Kubernetes"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP del servicio DNS de Kubernetes"
  type        = string
  default     = "10.1.0.10"
}

# Node Pool Configuration
variable "default_node_pool_name" {
  description = "Nombre del node pool por defecto"
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "Número de nodos"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "Tamaño de las VMs (ej: Standard_D2s_v3)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Habilitar auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Número mínimo de nodos para auto-scaling"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Número máximo de nodos para auto-scaling"
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  description = "Tamaño del disco OS en GB"
  type        = number
  default     = 50
}

variable "max_pods_per_node" {
  description = "Máximo de pods por nodo"
  type        = number
  default     = 30
}

# Identity
variable "identity_type" {
  description = "Tipo de identidad (SystemAssigned o UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

# RBAC y Security
variable "enable_rbac" {
  description = "Habilitar RBAC"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Habilitar Azure Policy"
  type        = bool
  default     = false
}

# Monitoring
variable "enable_monitoring" {
  description = "Habilitar Azure Monitor"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID del workspace de Log Analytics (opcional)"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default     = {}
}
