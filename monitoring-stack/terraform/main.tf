# ============================================
# Namespace para Monitoring
# ============================================

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    
    labels = {
      name        = var.monitoring_namespace
      environment = "shared"
      managed-by  = "terraform"
    }
  }
}

# ============================================
# Prometheus Stack (Prometheus + Alertmanager)
# ============================================

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.8.0"  # Versión estable
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Esperar a que el namespace esté listo
  depends_on = [kubernetes_namespace.monitoring]

  # Timeout más largo para la instalación
  timeout = 900
  wait    = false  # No esperar, verificar manualmente

  values = [
    yamlencode({
      # Usar imágenes de Docker Hub en lugar de quay.io
      server = {
        image = {
          repository = "prom/prometheus"
          tag        = "v2.48.0"
        }
        retention = var.prometheus_retention
        
        persistentVolume = {
          enabled = false  # Deshabilitar para evitar problemas de PVC
        }
        
        service = {
          type = var.expose_prometheus ? "LoadBalancer" : "ClusterIP"
        }
        
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }

        # Configuración global de scraping
        global = {
          scrape_interval     = "15s"
          evaluation_interval = "15s"
        }
      }

      # Alertmanager con imagen de Docker Hub
      alertmanager = {
        enabled = true
        image = {
          repository = "prom/alertmanager"
          tag        = "v0.26.0"
        }
        persistentVolume = {
          enabled = false
        }
        service = {
          type = "ClusterIP"
        }
      }

      # Config Map Reload
      configmapReload = {
        prometheus = {
          image = {
            repository = "jimmidyson/configmap-reload"
            tag        = "v0.9.0"
          }
        }
        alertmanager = {
          image = {
            repository = "jimmidyson/configmap-reload"
            tag        = "v0.9.0"
          }
        }
      }

      # Kube State Metrics - deshabilitado temporalmente por problemas de imagen
      kube-state-metrics = {
        enabled = false
      }

      # Node Exporter - métricas de los nodos
      prometheus-node-exporter = {
        enabled = true
        image = {
          registry   = "docker.io"
          repository = "prom/node-exporter"
          tag        = "v1.7.0"
        }
      }

      # Pushgateway - deshabilitado (no lo necesitamos)
      prometheus-pushgateway = {
        enabled = false
      }

      # Configuración de scraping adicional para microservicios
      extraScrapeConfigs = <<-EOF
        # Scrape microservicios en namespace prod
        - job_name: 'ecommerce-prod'
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - prod
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: 'true'
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: pod

        # Scrape microservicios en namespace staging
        - job_name: 'ecommerce-staging'
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - staging
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: 'true'
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: pod
      EOF
    })
  ]
}

# ============================================
# Grafana
# ============================================

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.0.0"  # Versión estable
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus
  ]

  timeout = 900
  wait    = false  # No esperar, verificar manualmente

  values = [
    yamlencode({
      # Imagen de Docker Hub
      image = {
        repository = "grafana/grafana"
        tag        = "10.2.0"
      }

      # Credenciales admin
      adminUser     = "admin"
      adminPassword = var.grafana_admin_password

      # Servicio
      service = {
        type = var.expose_grafana ? "LoadBalancer" : "ClusterIP"
        port = 80
      }

      # Persistencia deshabilitada para evitar problemas
      persistence = {
        enabled = false
      }

      # Recursos
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      # Datasources - conectar a Prometheus automáticamente
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server.${var.monitoring_namespace}.svc.cluster.local"
              access    = "proxy"
              isDefault = true
            }
          ]
        }
      }

      # Sin dashboards predefinidos por ahora (los puedes agregar después en la UI)
      dashboardProviders = {}
      dashboards         = {}

      # Sin plugins adicionales para evitar problemas de red
      plugins = []
    })
  ]
}
