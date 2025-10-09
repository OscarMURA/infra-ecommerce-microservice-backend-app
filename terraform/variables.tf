variable "digitalocean_token" {
  description = "Token de acceso personal para la API de DigitalOcean"
  type        = string
  sensitive   = true
}

variable "generate_ssh_key" {
  description = "Generar SSH key automáticamente (true) o usar key existente (false)"
  type        = bool
  default     = false
}

variable "ssh_public_key_path" {
  description = "Ruta a la SSH public key existente (solo si generate_ssh_key=false)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Ruta a la SSH private key existente (solo si generate_ssh_key=false)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_fingerprint" {
  description = "DEPRECATED: Ya no se usa. SSH key se gestiona automáticamente"
  type        = string
  default     = ""
}

variable "region" {
  description = "Región donde se crearán los droplets"
  type        = string
  default     = "nyc1"
}

variable "project_prefix" {
  description = "Prefijo para nombrar recursos del proyecto"
  type        = string
  default     = "infra-ecommerce"
}

variable "base_image" {
  description = "Imagen base para los droplets"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "dev_size" {
  description = "Tamaño del droplet para Dev"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "k8s_master_size" {
  description = "Tamaño del droplet para el nodo master Kubernetes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "k8s_worker_size" {
  description = "Tamaño del droplet para los nodos worker"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "k8s_worker_count" {
  description = "Cantidad de nodos worker a provisionar"
  type        = number
  default     = 2
}
