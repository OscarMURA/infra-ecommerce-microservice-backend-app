# ============================================
# Outputs - URLs y datos de acceso
# ============================================

output "cluster_name" {
  description = "Nombre del cluster GKE conectado"
  value       = data.google_container_cluster.existing.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster"
  value       = data.google_container_cluster.existing.endpoint
  sensitive   = true
}

output "monitoring_namespace" {
  description = "Namespace donde está instalado el monitoring"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service" {
  description = "Nombre del servicio de Prometheus"
  value       = "prometheus-server"
}

output "grafana_service" {
  description = "Nombre del servicio de Grafana"
  value       = "grafana"
}

output "grafana_admin_user" {
  description = "Usuario admin de Grafana"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "Contraseña admin de Grafana"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "access_instructions" {
  description = "Instrucciones para acceder a los servicios"
  value       = <<-EOF

    ╔══════════════════════════════════════════════════════════════╗
    ║           🎉 MONITORING STACK DESPLEGADO                     ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  📊 GRAFANA:                                                 ║
    ║     kubectl get svc grafana -n ${var.monitoring_namespace}              ║
    ║     Usuario: admin                                           ║
    ║     Password: (ver con: terraform output grafana_admin_password) ║
    ║                                                              ║
    ║  📈 PROMETHEUS:                                              ║
    ║     kubectl get svc prometheus-server -n ${var.monitoring_namespace}    ║
    ║                                                              ║
    ║  🔗 PORT-FORWARD (acceso local):                             ║
    ║     kubectl port-forward svc/grafana 3000:80 -n ${var.monitoring_namespace}     ║
    ║     kubectl port-forward svc/prometheus-server 9090:80 -n ${var.monitoring_namespace}║
    ║                                                              ║
    ║  Luego accede a:                                             ║
    ║     Grafana:    http://localhost:3000                        ║
    ║     Prometheus: http://localhost:9090                        ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

  EOF
}
