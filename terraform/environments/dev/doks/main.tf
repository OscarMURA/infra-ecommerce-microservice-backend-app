# Ambiente de Desarrollo - DOKS

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Provider de DigitalOcean
provider "digitalocean" {
  token = var.do_token
}

# Módulo DOKS
module "doks_cluster" {
  source = "../../../modules/doks"

  cluster_name        = var.cluster_name
  region              = var.region
  kubernetes_version  = var.kubernetes_version
  vpc_ip_range        = var.vpc_ip_range

  # Node Pool Configuration
  node_size           = var.node_size
  node_count          = var.node_count
  enable_auto_scaling = var.enable_auto_scaling
  min_nodes           = var.min_nodes
  max_nodes           = var.max_nodes

  # Tags y Labels
  tags = concat(
    var.tags,
    ["environment:dev", "terraform:true"]
  )
  node_labels = merge(
    var.node_labels,
    {
      "environment" = "dev"
    }
  )

  # Maintenance
  maintenance_day        = var.maintenance_day
  maintenance_start_time = var.maintenance_start_time

  # Critical Node Pool (opcional para dev)
  enable_critical_node_pool = var.enable_critical_node_pool
  critical_node_size        = var.critical_node_size
  critical_node_count       = var.critical_node_count
  critical_min_nodes        = var.critical_min_nodes
  critical_max_nodes        = var.critical_max_nodes

  # Firewall
  enable_firewall = var.enable_firewall

  # Container Registry
  enable_container_registry = var.enable_container_registry
  registry_name             = var.registry_name
  registry_tier             = var.registry_tier
  registry_region           = var.registry_region
}

# Guardar kubeconfig localmente (opcional, para debugging)
resource "local_file" "kubeconfig" {
  count = var.save_kubeconfig ? 1 : 0

  content  = module.doks_cluster.kubeconfig
  filename = "${path.module}/kubeconfig-${var.cluster_name}.yaml"

  file_permission = "0600"
}
