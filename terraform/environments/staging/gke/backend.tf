# Backend configuration para staging - GKE

terraform {
  # Para producción, usar backend remoto
  # backend "gcs" {
  #   bucket  = "ecommerce-terraform-state"
  #   prefix  = "staging/gke"
  # }

  # Temporal para desarrollo
  backend "local" {
    path = "terraform.tfstate"
  }
}
