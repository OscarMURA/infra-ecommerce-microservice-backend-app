output "cluster_id" {
  description = "ID del cluster AKS"
  value       = module.aks_cluster.cluster_id
}

output "cluster_name" {
  description = "Nombre del cluster AKS"
  value       = module.aks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster AKS"
  value       = module.aks_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN del cluster AKS"
  value       = module.aks_cluster.cluster_fqdn
}

output "resource_group_name" {
  description = "Nombre del grupo de recursos"
  value       = module.aks_cluster.resource_group_name
}

output "kube_config_command" {
  description = "Comando para obtener la configuración de kubectl"
  value       = "az aks get-credentials --resource-group ${module.aks_cluster.resource_group_name} --name ${module.aks_cluster.cluster_name}"
}
