output "dev_ips" {
  value       = [digitalocean_droplet.dev.ipv4_address]
  description = "Dirección IP pública de la VM Dev"
}

output "stage_master" {
  value       = digitalocean_droplet.stage_master.ipv4_address
  description = "Dirección IP pública del master de Stage"
}

output "stage_workers" {
  value       = [for droplet in digitalocean_droplet.stage_workers : droplet.ipv4_address]
  description = "Direcciones IP públicas de los workers de Stage"
}
