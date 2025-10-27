terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  description = "Name for the Minikube VM"
  type        = string
  default     = "ecommerce-minikube-dev"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "size" {
  description = "Droplet size"
  type        = string
  default     = "s-2vcpu-4gb"  # 4GB RAM, 2 CPUs for Minikube
}

variable "vm_password" {
  description = "Password for the jenkins user"
  type        = string
  sensitive   = true
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "minikube_vm" {
  name   = var.vm_name
  region = var.region
  size   = var.size
  image  = "ubuntu-22-04-x64"

  # Minimal cloud-init - only SSH and basic setup
  user_data = <<-EOF
#cloud-config
hostname: ecommerce-minikube-vm
manage_etc_hosts: true
ssh_pwauth: true

users:
  - name: jenkins
    gecos: Jenkins CI Runner
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

chpasswd:
  list: |
    jenkins:${var.vm_password}
  expire: false

package_update: true
packages:
  - ca-certificates
  - curl
  - gnupg
  - ufw
  - jq
  - git
  - build-essential
  - python3
  - python3-pip
  - openssh-client

write_files:
  - path: /etc/motd
    permissions: '0644'
    owner: root:root
    content: |
      Bienvenido a la VM de Minikube de ecommerce.
      Este host fue aprovisionado automáticamente por Jenkins para ejecutar pruebas con Minikube.

runcmd:
  - sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl reload ssh || systemctl restart ssh
  - ufw allow 22/tcp
  - ufw allow 3000,8000,8080,8081,8082,8083,9411/tcp
  - ufw allow 8443/tcp  # Kubernetes API
  - ufw allow 30000:32767/tcp  # NodePort range
  - ufw --force enable
  - mkdir -p /opt/ecommerce-app
  - chown -R jenkins:jenkins /opt/ecommerce-app
  - pip3 install --upgrade pip

final_message: "Cloud-init finished. Minikube VM is ready. Docker, kubectl, and Minikube will be installed via Ansible."
EOF

  tags = ["minikube", "ecommerce", "jenkins"]
}

output "droplet_id" {
  description = "ID of the droplet"
  value       = digitalocean_droplet.minikube_vm.id
}

output "droplet_name" {
  description = "Name of the droplet"
  value       = digitalocean_droplet.minikube_vm.name
}

output "droplet_ip" {
  description = "Public IP of the droplet"
  value       = digitalocean_droplet.minikube_vm.ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect to the droplet"
  value       = "ssh jenkins@${digitalocean_droplet.minikube_vm.ipv4_address}"
}