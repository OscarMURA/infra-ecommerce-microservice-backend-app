variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
}

variable "tenant_id" {
  description = "ID del tenant de Azure AD"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "ecommerce-aks-staging"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "ecommerce-rg-staging"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el cluster"
  type        = string
  default     = "ecommerce-staging"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.31.11"
}

variable "vnet_address_space" {
  description = "CIDR de la VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "CIDR de la subnet para AKS"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "network_plugin" {
  description = "Plugin de red"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR para servicios"
  type        = string
  default     = "10.11.0.0/16"
}

variable "dns_service_ip" {
  description = "IP del servicio DNS"
  type        = string
  default     = "10.11.0.10"
}

variable "default_node_pool_name" {
  description = "Nombre del node pool"
  type        = string
  default     = "default"
}

variable "node_size" {
  description = "Tamaño de las VMs"
  type        = string
  default     = "Standard_D4s_v3"  # 4 vCPUs, 16 GB RAM para staging
}

variable "node_count" {
  description = "Número inicial de nodos"
  type        = number
  default     = 3
}

variable "enable_auto_scaling" {
  description = "Habilitar auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Número máximo de nodos"
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  description = "Tamaño del disco OS en GB"
  type        = number
  default     = 100
}

variable "max_pods_per_node" {
  description = "Máximo de pods por nodo"
  type        = number
  default     = 50
}

variable "identity_type" {
  description = "Tipo de identidad"
  type        = string
  default     = "SystemAssigned"
}

variable "enable_rbac" {
  description = "Habilitar RBAC"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Habilitar Azure Policy"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Habilitar Azure Monitor"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    "project"     = "ecommerce"
    "environment" = "staging"
  }
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default = {
    "workload" = "general"
  }
}
