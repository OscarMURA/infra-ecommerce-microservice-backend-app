# Variables para Ambiente de Desarrollo - AKS

# Azure Credentials
variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
}

variable "tenant_id" {
  description = "ID del tenant de Azure AD"
  type        = string
}

# Cluster Configuration
variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "ecommerce-aks-dev"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "ecommerce-rg-dev"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el cluster"
  type        = string
  default     = "ecommerce-dev"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.31.11"
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

variable "node_size" {
  description = "Tamaño de las VMs para desarrollo"
  type        = string
  default     = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
}

variable "node_count" {
  description = "Número inicial de nodos"
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
  description = "Tipo de identidad"
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

# Tags
variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    "project"     = "ecommerce"
    "environment" = "dev"
  }
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default = {
    "workload" = "general"
  }
}
