# Kubernetes Configuration Module
# Este módulo configura recursos base en el cluster de Kubernetes

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Namespace para la aplicación de e-commerce
resource "kubernetes_namespace" "ecommerce" {
  metadata {
    name = var.namespace_name
    labels = merge(
      var.namespace_labels,
      {
        "app"       = "ecommerce"
        "terraform" = "true"
      }
    )
  }
}

# Namespace para monitoring
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = "monitoring"
    labels = {
      "purpose"   = "monitoring"
      "terraform" = "true"
    }
  }
}

# Namespace para logging
resource "kubernetes_namespace" "logging" {
  count = var.enable_logging ? 1 : 0

  metadata {
    name = "logging"
    labels = {
      "purpose"   = "logging"
      "terraform" = "true"
    }
  }
}

# ConfigMap para configuración de la aplicación
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "ecommerce-config"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  data = var.app_config_data
}

# Secret para credenciales de base de datos
resource "kubernetes_secret" "db_credentials" {
  count = var.create_db_secret ? 1 : 0

  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = base64encode(var.db_username)
    password = base64encode(var.db_password)
  }
}

# Secret para registry de Docker (si se usa un registry privado)
resource "kubernetes_secret" "docker_registry" {
  count = var.create_docker_registry_secret ? 1 : 0

  metadata {
    name      = "docker-registry-secret"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_registry_server) = {
          username = var.docker_registry_username
          password = var.docker_registry_password
          email    = var.docker_registry_email
          auth     = base64encode("${var.docker_registry_username}:${var.docker_registry_password}")
        }
      }
    })
  }
}

# Service Account para la aplicación
resource "kubernetes_service_account" "app" {
  metadata {
    name      = "ecommerce-app-sa"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
    annotations = var.service_account_annotations
  }

  dynamic "image_pull_secret" {
    for_each = var.create_docker_registry_secret ? [1] : []
    content {
      name = kubernetes_secret.docker_registry[0].metadata[0].name
    }
  }
}

# Resource Quotas para el namespace
resource "kubernetes_resource_quota" "namespace_quota" {
  count = var.enable_resource_quota ? 1 : 0

  metadata {
    name      = "namespace-quota"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_requests_cpu
      "requests.memory" = var.quota_requests_memory
      "limits.cpu"      = var.quota_limits_cpu
      "limits.memory"   = var.quota_limits_memory
      "pods"            = var.quota_pods
    }
  }
}

# Limit Range para el namespace
resource "kubernetes_limit_range" "namespace_limits" {
  count = var.enable_limit_range ? 1 : 0

  metadata {
    name      = "namespace-limits"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  spec {
    limit {
      type = "Pod"
      max = {
        cpu    = var.pod_max_cpu
        memory = var.pod_max_memory
      }
      min = {
        cpu    = var.pod_min_cpu
        memory = var.pod_min_memory
      }
    }

    limit {
      type = "Container"
      default = {
        cpu    = var.container_default_cpu
        memory = var.container_default_memory
      }
      default_request = {
        cpu    = var.container_default_request_cpu
        memory = var.container_default_request_memory
      }
      max = {
        cpu    = var.container_max_cpu
        memory = var.container_max_memory
      }
      min = {
        cpu    = var.container_min_cpu
        memory = var.container_min_memory
      }
    }
  }
}

# Network Policy - Permitir tráfico solo dentro del namespace
resource "kubernetes_network_policy" "namespace_isolation" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "namespace-isolation"
    namespace = kubernetes_namespace.ecommerce.metadata[0].name
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.ecommerce.metadata[0].name
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.ecommerce.metadata[0].name
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# Storage Class (si es necesario personalizar)
resource "kubernetes_storage_class" "fast_ssd" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = "fast-ssd"
  }

  storage_provisioner = var.storage_provisioner
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = var.storage_class_parameters
}

# Instalar NGINX Ingress Controller con Helm
resource "helm_release" "nginx_ingress" {
  count = var.install_nginx_ingress ? 1 : 0

  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_version
  namespace  = kubernetes_namespace.ecommerce.metadata[0].name

  values = [
    yamlencode({
      controller = {
        service = {
          type = var.nginx_ingress_service_type
        }
        metrics = {
          enabled = true
        }
        resources = var.nginx_ingress_resources
      }
    })
  ]
}

# Instalar Cert-Manager para certificados SSL (opcional)
resource "helm_release" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
