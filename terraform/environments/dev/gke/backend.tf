# Terraform Backend Configuration para dev - GKE

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  # Para producción, usar backend remoto:
  # backend "gcs" {
  #   bucket  = "ecommerce-terraform-state"
  #   prefix  = "dev/gke"
  # }
}
