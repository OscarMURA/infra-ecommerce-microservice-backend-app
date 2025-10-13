# Ambiente de Producción - DOKS

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

module "doks_cluster" {
  source = "../../../modules/doks"

  cluster_name        = var.cluster_name
  region              = var.region
  kubernetes_version  = var.kubernetes_version
  vpc_ip_range        = var.vpc_ip_range

  # Node Pool Configuration - Más robusto para producción
  node_size           = var.node_size
  node_count          = var.node_count
  enable_auto_scaling = var.enable_auto_scaling
  min_nodes           = var.min_nodes
  max_nodes           = var.max_nodes

  tags = concat(
    var.tags,
    ["environment:prod", "terraform:true", "critical:true"]
  )
  node_labels = merge(
    var.node_labels,
    {
      "environment" = "prod"
    }
  )

  maintenance_day        = var.maintenance_day
  maintenance_start_time = var.maintenance_start_time

  # Critical Node Pool - Recomendado para producción
  enable_critical_node_pool = var.enable_critical_node_pool
  critical_node_size        = var.critical_node_size
  critical_node_count       = var.critical_node_count
  critical_min_nodes        = var.critical_min_nodes
  critical_max_nodes        = var.critical_max_nodes

  enable_firewall = var.enable_firewall

  # Container Registry - Recomendado para producción
  enable_container_registry = var.enable_container_registry
  registry_name             = var.registry_name
  registry_tier             = var.registry_tier
  registry_region           = var.registry_region
}
