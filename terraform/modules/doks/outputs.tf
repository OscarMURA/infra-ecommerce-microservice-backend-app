# Outputs del módulo DOKS

output "cluster_id" {
  description = "ID del cluster de Kubernetes"
  value       = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Nombre del cluster"
  value       = digitalocean_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster"
  value       = digitalocean_kubernetes_cluster.main.endpoint
}

output "cluster_region" {
  description = "Región del cluster"
  value       = digitalocean_kubernetes_cluster.main.region
}

output "cluster_version" {
  description = "Versión de Kubernetes"
  value       = digitalocean_kubernetes_cluster.main.version
}

output "cluster_status" {
  description = "Estado del cluster"
  value       = digitalocean_kubernetes_cluster.main.status
}

output "cluster_ipv4_address" {
  description = "Dirección IPv4 del cluster"
  value       = digitalocean_kubernetes_cluster.main.ipv4_address
}

output "cluster_urn" {
  description = "URN del cluster"
  value       = digitalocean_kubernetes_cluster.main.urn
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = digitalocean_vpc.kubernetes_vpc.id
}

output "vpc_urn" {
  description = "URN de la VPC"
  value       = digitalocean_vpc.kubernetes_vpc.urn
}

output "node_pool_id" {
  description = "ID del node pool por defecto"
  value       = digitalocean_kubernetes_cluster.main.node_pool[0].id
}

output "node_pool_nodes" {
  description = "Información de los nodos"
  value       = digitalocean_kubernetes_cluster.main.node_pool[0].nodes
}

output "critical_node_pool_id" {
  description = "ID del node pool crítico"
  value       = var.enable_critical_node_pool ? digitalocean_kubernetes_node_pool.critical_services[0].id : null
}

output "kubeconfig" {
  description = "Kubeconfig para conectarse al cluster"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster"
  value       = base64decode(digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  sensitive   = true
}

output "client_certificate" {
  description = "Certificado del cliente"
  value       = base64decode(digitalocean_kubernetes_cluster.main.kube_config[0].client_certificate)
  sensitive   = true
}

output "client_key" {
  description = "Llave del cliente"
  value       = base64decode(digitalocean_kubernetes_cluster.main.kube_config[0].client_key)
  sensitive   = true
}

output "registry_endpoint" {
  description = "Endpoint del container registry"
  value       = var.enable_container_registry ? digitalocean_container_registry.main[0].endpoint : null
}

output "registry_server_url" {
  description = "URL del servidor del registry"
  value       = var.enable_container_registry ? digitalocean_container_registry.main[0].server_url : null
}

output "firewall_id" {
  description = "ID del firewall"
  value       = var.enable_firewall ? digitalocean_firewall.kubernetes[0].id : null
}
