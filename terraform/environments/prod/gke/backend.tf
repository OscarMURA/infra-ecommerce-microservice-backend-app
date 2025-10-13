# Backend remoto para producción - GKE

terraform {
  # Backend remoto en GCS (recomendado para GKE)
  # backend "gcs" {
  #   bucket  = "ecommerce-terraform-state"
  #   prefix  = "prod/gke"
  # }

  # Temporal para desarrollo
  backend "local" {
    path = "terraform.tfstate"
  }
}
