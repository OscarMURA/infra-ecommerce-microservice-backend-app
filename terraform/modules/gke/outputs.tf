# Outputs del módulo GKE

output "cluster_id" {
  description = "ID del cluster de GKE"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "Nombre del cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Ubicación del cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_region" {
  description = "Región del cluster"
  value       = var.region
}

output "cluster_type" {
  description = "Tipo de cluster (regional o zonal)"
  value       = var.regional ? "regional" : "zonal"
}

output "master_version" {
  description = "Versión del control plane"
  value       = google_container_cluster.primary.master_version
}

output "node_version" {
  description = "Versión de los nodos"
  value       = google_container_node_pool.primary_nodes.version
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID de la subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "Nombre de la subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "service_account_email" {
  description = "Email de la service account"
  value       = google_service_account.kubernetes.email
}

output "service_account_name" {
  description = "Nombre de la service account"
  value       = google_service_account.kubernetes.name
}

output "node_pool_id" {
  description = "ID del node pool por defecto"
  value       = google_container_node_pool.primary_nodes.id
}

output "node_pool_name" {
  description = "Nombre del node pool por defecto"
  value       = google_container_node_pool.primary_nodes.name
}

output "critical_node_pool_id" {
  description = "ID del node pool crítico"
  value       = var.enable_critical_node_pool ? google_container_node_pool.critical_nodes[0].id : null
}

output "critical_node_pool_name" {
  description = "Nombre del node pool crítico"
  value       = var.enable_critical_node_pool ? google_container_node_pool.critical_nodes[0].name : null
}

output "cluster_ipv4_cidr" {
  description = "CIDR IPv4 del cluster"
  value       = google_container_cluster.primary.cluster_ipv4_cidr
}

output "services_ipv4_cidr" {
  description = "CIDR IPv4 de los servicios"
  value       = google_container_cluster.primary.services_ipv4_cidr
}

output "workload_identity_pool" {
  description = "Workload Identity Pool"
  value       = "${var.project_id}.svc.id.goog"
}

output "kubeconfig_command" {
  description = "Comando para obtener kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
