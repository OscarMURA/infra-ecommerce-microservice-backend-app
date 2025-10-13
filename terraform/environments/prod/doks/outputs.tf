# Outputs para ambiente prod - DOKS

output "cluster_id" {
  description = "ID del cluster"
  value       = module.doks_cluster.cluster_id
}

output "cluster_name" {
  description = "Nombre del cluster"
  value       = module.doks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster"
  value       = module.doks_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_region" {
  description = "Región del cluster"
  value       = module.doks_cluster.cluster_region
}

output "cluster_version" {
  description = "Versión de Kubernetes"
  value       = module.doks_cluster.cluster_version
}

output "cluster_status" {
  description = "Estado del cluster"
  value       = module.doks_cluster.cluster_status
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = module.doks_cluster.vpc_id
}

output "node_pool_id" {
  description = "ID del node pool"
  value       = module.doks_cluster.node_pool_id
}

output "critical_node_pool_id" {
  description = "ID del node pool crítico"
  value       = module.doks_cluster.critical_node_pool_id
}

output "kubeconfig_command" {
  description = "Comando para configurar kubectl"
  value       = "doctl kubernetes cluster kubeconfig save ${module.doks_cluster.cluster_name}"
}

output "registry_endpoint" {
  description = "Endpoint del container registry"
  value       = module.doks_cluster.registry_endpoint
}

output "registry_server_url" {
  description = "URL del servidor del registry"
  value       = module.doks_cluster.registry_server_url
}
