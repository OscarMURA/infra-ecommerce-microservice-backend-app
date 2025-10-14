# Ambiente de Desarrollo - GKE

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Provider de Google Cloud
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
}

# Módulo GKE
module "gke_cluster" {
  source = "../../../modules/gke"

  project_id     = var.project_id
  cluster_name   = var.cluster_name
  region         = var.region
  zone           = var.zone
  regional       = var.regional

  # Versión de Kubernetes
  kubernetes_version = var.kubernetes_version
  release_channel    = var.release_channel

  # Network Configuration
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  # Private Cluster
  enable_private_nodes    = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks

  # Node Pool
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type
  image_type   = var.image_type

  node_count         = var.node_count
  node_count_per_zone = var.node_count_per_zone
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count

  auto_repair  = var.auto_repair
  auto_upgrade = var.auto_upgrade

  # Labels y Tags
  labels = merge(
    var.labels,
    {
      "environment" = "dev"
      "terraform"   = "true"
    }
  )
  node_labels = merge(
    var.node_labels,
    {
      "environment" = "dev"
    }
  )
  node_tags = var.node_tags

  # Critical Node Pool (opcional para dev)
  enable_critical_node_pool    = var.enable_critical_node_pool
  critical_machine_type        = var.critical_machine_type
  critical_disk_size_gb        = var.critical_disk_size_gb
  critical_node_count          = var.critical_node_count
  critical_node_count_per_zone = var.critical_node_count_per_zone
  critical_min_node_count      = var.critical_min_node_count
  critical_max_node_count      = var.critical_max_node_count

  # Maintenance
  maintenance_start_time = var.maintenance_start_time

  # Addons
  enable_http_load_balancing         = var.enable_http_load_balancing
  enable_horizontal_pod_autoscaling  = var.enable_horizontal_pod_autoscaling
  enable_network_policy              = var.enable_network_policy
  enable_gce_persistent_disk_csi_driver = var.enable_gce_persistent_disk_csi_driver

  # Logging y Monitoring
  logging_components    = var.logging_components
  monitoring_components = var.monitoring_components
  enable_managed_prometheus = var.enable_managed_prometheus

  # Security
  enable_binary_authorization   = var.enable_binary_authorization
  enable_secure_boot            = var.enable_secure_boot
  enable_integrity_monitoring   = var.enable_integrity_monitoring
}
