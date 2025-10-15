# Outputs del módulo AKS

output "cluster_id" {
  description = "ID del cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN del cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config" {
  description = "Configuración de kubectl"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config_map" {
  description = "Mapa de configuración de kubectl"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0]
  sensitive   = true
}

output "client_certificate" {
  description = "Certificado del cliente"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Llave del cliente"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "resource_group_name" {
  description = "Nombre del grupo de recursos"
  value       = azurerm_resource_group.aks.name
}

output "resource_group_id" {
  description = "ID del grupo de recursos"
  value       = azurerm_resource_group.aks.id
}

output "location" {
  description = "Región de Azure"
  value       = azurerm_resource_group.aks.location
}

output "node_resource_group" {
  description = "Grupo de recursos de los nodos"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity" {
  description = "Identidad del kubelet"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0]
}

output "principal_id" {
  description = "ID principal de la identidad del cluster"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "log_analytics_workspace_id" {
  description = "ID del workspace de Log Analytics"
  value       = var.enable_monitoring && var.log_analytics_workspace_id == null ? azurerm_log_analytics_workspace.aks[0].id : var.log_analytics_workspace_id
}
