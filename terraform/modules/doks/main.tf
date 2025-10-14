# DigitalOcean Kubernetes Service (DOKS) Module

# VPC para el cluster
resource "digitalocean_vpc" "kubernetes_vpc" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}

# Kubernetes Cluster
resource "digitalocean_kubernetes_cluster" "main" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version
  vpc_uuid = digitalocean_vpc.kubernetes_vpc.id
  
  # Destruir automáticamente todos los recursos asociados (LBs, volumes, etc.)
  destroy_all_associated_resources = true

  tags = concat(var.tags, ["terraform", "ecommerce"])

  # Node Pool por defecto
  node_pool {
    name       = "${var.cluster_name}-default-pool"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = var.enable_auto_scaling
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
    tags       = var.tags
    labels     = var.node_labels
  }

  maintenance_policy {
    day        = var.maintenance_day
    start_time = var.maintenance_start_time
  }
}

# Node Pool adicional para servicios críticos (opcional)
resource "digitalocean_kubernetes_node_pool" "critical_services" {
  count = var.enable_critical_node_pool ? 1 : 0

  cluster_id = digitalocean_kubernetes_cluster.main.id
  name       = "${var.cluster_name}-critical-pool"
  size       = var.critical_node_size
  node_count = var.critical_node_count
  auto_scale = var.enable_auto_scaling
  min_nodes  = var.critical_min_nodes
  max_nodes  = var.critical_max_nodes
  tags       = concat(var.tags, ["critical"])
  
  labels = merge(
    var.node_labels,
    {
      "workload-type" = "critical"
    }
  )

  taint {
    key    = "critical"
    value  = "true"
    effect = "NoSchedule"
  }
}

# Firewall para el cluster
resource "digitalocean_firewall" "kubernetes" {
  count = var.enable_firewall ? 1 : 0

  name = "${var.cluster_name}-firewall"
  tags = digitalocean_kubernetes_cluster.main.node_pool[0].tags

  # Reglas de entrada
  dynamic "inbound_rule" {
    for_each = var.firewall_inbound_rules
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range != "" ? inbound_rule.value.port_range : null
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  # Reglas de salida
  dynamic "outbound_rule" {
    for_each = var.firewall_outbound_rules
    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range != "" ? outbound_rule.value.port_range : null
      destination_addresses = outbound_rule.value.destination_addresses
    }
  }
}

# Container Registry
resource "digitalocean_container_registry" "main" {
  count = var.enable_container_registry ? 1 : 0

  name                   = var.registry_name
  subscription_tier_slug = var.registry_tier
  region                 = var.registry_region
}

# Conectar el registry al cluster
resource "digitalocean_container_registry_docker_credentials" "main" {
  count = var.enable_container_registry ? 1 : 0

  registry_name = digitalocean_container_registry.main[0].name
  write         = false
}
