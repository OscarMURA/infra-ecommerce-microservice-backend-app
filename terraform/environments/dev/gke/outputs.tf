# Outputs para ambiente dev - GKE

output "cluster_id" {
  description = "ID del cluster"
  value       = module.gke_cluster.cluster_id
}

output "cluster_name" {
  description = "Nombre del cluster"
  value       = module.gke_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster"
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Ubicación del cluster"
  value       = module.gke_cluster.cluster_location
}

output "cluster_type" {
  description = "Tipo de cluster"
  value       = module.gke_cluster.cluster_type
}

output "master_version" {
  description = "Versión del master"
  value       = module.gke_cluster.master_version
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = module.gke_cluster.vpc_name
}

output "subnet_name" {
  description = "Nombre de la subnet"
  value       = module.gke_cluster.subnet_name
}

output "service_account_email" {
  description = "Email de la service account"
  value       = module.gke_cluster.service_account_email
}

output "node_pool_name" {
  description = "Nombre del node pool"
  value       = module.gke_cluster.node_pool_name
}

output "kubeconfig_command" {
  description = "Comando para configurar kubectl"
  value       = module.gke_cluster.kubeconfig_command
}
