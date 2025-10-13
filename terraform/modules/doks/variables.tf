# Variables para el módulo DOKS

variable "cluster_name" {
  description = "Nombre del cluster de Kubernetes"
  type        = string
}

variable "region" {
  description = "Región de DigitalOcean"
  type        = string
  default     = "nyc1"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28.2-do.0"
}

variable "vpc_ip_range" {
  description = "Rango de IPs para la VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "node_size" {
  description = "Tamaño de los nodos (droplet size)"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Número de nodos en el pool por defecto"
  type        = number
  default     = 3
}

variable "enable_auto_scaling" {
  description = "Habilitar auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Número mínimo de nodos para auto-scaling"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Número máximo de nodos para auto-scaling"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags para los recursos"
  type        = list(string)
  default     = []
}

variable "node_labels" {
  description = "Labels para los nodos"
  type        = map(string)
  default     = {}
}

variable "maintenance_day" {
  description = "Día de mantenimiento (monday, tuesday, etc.)"
  type        = string
  default     = "sunday"
}

variable "maintenance_start_time" {
  description = "Hora de inicio del mantenimiento (HH:MM)"
  type        = string
  default     = "04:00"
}

# Variables para node pool crítico
variable "enable_critical_node_pool" {
  description = "Crear un node pool adicional para servicios críticos"
  type        = bool
  default     = false
}

variable "critical_node_size" {
  description = "Tamaño de los nodos críticos"
  type        = string
  default     = "s-4vcpu-8gb"
}

variable "critical_node_count" {
  description = "Número de nodos en el pool crítico"
  type        = number
  default     = 2
}

variable "critical_min_nodes" {
  description = "Número mínimo de nodos críticos"
  type        = number
  default     = 1
}

variable "critical_max_nodes" {
  description = "Número máximo de nodos críticos"
  type        = number
  default     = 3
}

# Variables para Firewall
variable "enable_firewall" {
  description = "Habilitar firewall para el cluster"
  type        = bool
  default     = true
}

variable "firewall_inbound_rules" {
  description = "Reglas de entrada del firewall"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = [
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

variable "firewall_outbound_rules" {
  description = "Reglas de salida del firewall"
  type = list(object({
    protocol              = string
    port_range            = string
    destination_addresses = list(string)
  }))
  default = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = ""
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

# Variables para Container Registry
variable "enable_container_registry" {
  description = "Crear un container registry"
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Nombre del container registry"
  type        = string
  default     = ""
}

variable "registry_tier" {
  description = "Tier del container registry (starter, basic, professional)"
  type        = string
  default     = "basic"
}

variable "registry_region" {
  description = "Región del container registry"
  type        = string
  default     = "nyc3"
}
