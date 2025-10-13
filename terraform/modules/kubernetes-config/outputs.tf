# Outputs del módulo Kubernetes Config

output "namespace_name" {
  description = "Nombre del namespace principal"
  value       = kubernetes_namespace.ecommerce.metadata[0].name
}

output "namespace_id" {
  description = "ID del namespace"
  value       = kubernetes_namespace.ecommerce.id
}

output "monitoring_namespace" {
  description = "Nombre del namespace de monitoring"
  value       = var.enable_monitoring ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "logging_namespace" {
  description = "Nombre del namespace de logging"
  value       = var.enable_logging ? kubernetes_namespace.logging[0].metadata[0].name : null
}

output "config_map_name" {
  description = "Nombre del ConfigMap"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "service_account_name" {
  description = "Nombre de la service account"
  value       = kubernetes_service_account.app.metadata[0].name
}

output "db_secret_name" {
  description = "Nombre del secret de base de datos"
  value       = var.create_db_secret ? kubernetes_secret.db_credentials[0].metadata[0].name : null
}

output "docker_registry_secret_name" {
  description = "Nombre del secret de Docker registry"
  value       = var.create_docker_registry_secret ? kubernetes_secret.docker_registry[0].metadata[0].name : null
}

output "storage_class_name" {
  description = "Nombre del storage class"
  value       = var.create_storage_class ? kubernetes_storage_class.fast_ssd[0].metadata[0].name : null
}

output "nginx_ingress_installed" {
  description = "NGINX Ingress Controller instalado"
  value       = var.install_nginx_ingress
}

output "cert_manager_installed" {
  description = "Cert-Manager instalado"
  value       = var.install_cert_manager
}
