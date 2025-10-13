# Backend configuration para staging - DOKS

terraform {
  # Para producción, usar backend remoto
  # backend "s3" {
  #   bucket         = "ecommerce-terraform-state"
  #   key            = "staging/doks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }

  # Temporal para desarrollo
  backend "local" {
    path = "terraform.tfstate"
  }
}
