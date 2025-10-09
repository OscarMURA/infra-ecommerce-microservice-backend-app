terraform {
  required_version = ">= 1.4.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

# Generar SSH key automáticamente si se requiere
resource "tls_private_key" "generated_key" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Guardar private key localmente
resource "local_file" "private_key" {
  count           = var.generate_ssh_key ? 1 : 0
  content         = tls_private_key.generated_key[0].private_key_pem
  filename        = "${path.module}/../.ssh/terraform_rsa"
  file_permission = "0600"
}

# Guardar public key localmente
resource "local_file" "public_key" {
  count           = var.generate_ssh_key ? 1 : 0
  content         = tls_private_key.generated_key[0].public_key_openssh
  filename        = "${path.module}/../.ssh/terraform_rsa.pub"
  file_permission = "0644"
}

# Subir la SSH key generada a DigitalOcean
resource "digitalocean_ssh_key" "generated_key" {
  count      = var.generate_ssh_key ? 1 : 0
  name       = "${var.project_prefix}-generated-key"
  public_key = tls_private_key.generated_key[0].public_key_openssh
}

# Subir SSH key existente a DigitalOcean (si no se genera automáticamente)
resource "digitalocean_ssh_key" "existing_key" {
  count      = var.generate_ssh_key ? 0 : 1
  name       = "${var.project_prefix}-existing-key"
  public_key = file(var.ssh_public_key_path)
}

# Local para seleccionar la SSH key correcta
locals {
  ssh_key_id = var.generate_ssh_key ? digitalocean_ssh_key.generated_key[0].id : digitalocean_ssh_key.existing_key[0].id
  ssh_key_path = var.generate_ssh_key ? "${path.module}/../.ssh/terraform_rsa" : var.ssh_private_key_path
}

# VM para desarrollo
resource "digitalocean_droplet" "dev" {
  name     = "${var.project_prefix}-dev"
  region   = var.region
  size     = var.dev_size
  image    = var.base_image
  ssh_keys = [local.ssh_key_id]
  tags = [
    var.project_prefix,
    "dev"
  ]
}

# Master de Kubernetes para Stage
resource "digitalocean_droplet" "stage_master" {
  name     = "${var.project_prefix}-stage-master"
  region   = var.region
  size     = var.k8s_master_size
  image    = var.base_image
  ssh_keys = [local.ssh_key_id]
  tags = [
    var.project_prefix,
    "stage",
    "k8s-master"
  ]
}

# Workers de Kubernetes para Stage (escalables)
resource "digitalocean_droplet" "stage_workers" {
  count    = var.k8s_worker_count
  name     = "${var.project_prefix}-stage-worker-${count.index + 1}"
  region   = var.region
  size     = var.k8s_worker_size
  image    = var.base_image
  ssh_keys = [local.ssh_key_id]
  tags = [
    var.project_prefix,
    "stage",
    "k8s-worker"
  ]
}

# Generar inventario de Ansible automáticamente
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    dev_ips       = [digitalocean_droplet.dev.ipv4_address]
    stage_master  = digitalocean_droplet.stage_master.ipv4_address
    stage_workers = digitalocean_droplet.stage_workers[*].ipv4_address
    ssh_key_path  = local.ssh_key_path
  })
  filename = "${path.module}/../ansible/inventories/dev.ini"
  
  depends_on = [
    digitalocean_droplet.dev,
    digitalocean_droplet.stage_master,
    digitalocean_droplet.stage_workers
  ]
}
