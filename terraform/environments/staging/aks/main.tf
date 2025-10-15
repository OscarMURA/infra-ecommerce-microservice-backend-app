# Ambiente de Staging - AKS
# Usa el mismo módulo pero con configuraciones más robustas

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

module "aks_cluster" {
  source = "../../../modules/aks"

  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  network_plugin        = var.network_plugin
  service_cidr          = var.service_cidr
  dns_service_ip        = var.dns_service_ip

  default_node_pool_name = var.default_node_pool_name
  node_size              = var.node_size
  node_count             = var.node_count
  enable_auto_scaling    = var.enable_auto_scaling
  min_nodes              = var.min_nodes
  max_nodes              = var.max_nodes
  os_disk_size_gb        = var.os_disk_size_gb
  max_pods_per_node      = var.max_pods_per_node

  identity_type = var.identity_type

  enable_rbac         = var.enable_rbac
  enable_azure_policy = var.enable_azure_policy
  enable_monitoring   = var.enable_monitoring

  tags = merge(
    var.tags,
    {
      "environment" = "staging"
      "terraform"   = "true"
      "managed-by"  = "terraform"
    }
  )
  
  node_labels = merge(
    var.node_labels,
    {
      "environment" = "staging"
    }
  )
}
