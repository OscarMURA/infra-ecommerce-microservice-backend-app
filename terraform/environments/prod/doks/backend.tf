# Backend remoto para producción - DOKS
# Usar S3 o equivalente para almacenar el estado

terraform {
  # Configurar backend remoto (S3, GCS, etc.)
  # backend "s3" {
  #   bucket         = "ecommerce-terraform-state"
  #   key            = "prod/doks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }

  # Para DigitalOcean Spaces (compatible S3)
  # backend "s3" {
  #   endpoint                    = "nyc3.digitaloceanspaces.com"
  #   bucket                      = "ecommerce-terraform-state"
  #   key                         = "prod/doks/terraform.tfstate"
  #   region                      = "us-east-1"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  # }

  # Temporal para desarrollo
  backend "local" {
    path = "terraform.tfstate"
  }
}
