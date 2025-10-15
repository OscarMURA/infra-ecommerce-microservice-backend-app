# Azure Kubernetes Service (AKS) Module

# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "aks" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet para AKS
resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = var.subnet_address_prefix
}

# Log Analytics Workspace (para monitoring)
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_monitoring && var.log_analytics_workspace_id == null ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = var.default_node_pool_name
    node_count          = var.enable_auto_scaling ? null : var.node_count
    vm_size             = var.node_size
    os_disk_size_gb     = var.os_disk_size_gb
    vnet_subnet_id      = azurerm_subnet.aks.id
    max_pods            = var.max_pods_per_node
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_nodes : null
    max_count           = var.enable_auto_scaling ? var.max_nodes : null
    node_labels         = var.node_labels

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = var.identity_type
  }

  network_profile {
    network_plugin     = var.network_plugin
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    load_balancer_sku  = "standard"
  }

  role_based_access_control_enabled = var.enable_rbac
  azure_policy_enabled               = var.enable_azure_policy

  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.aks[0].id
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}
