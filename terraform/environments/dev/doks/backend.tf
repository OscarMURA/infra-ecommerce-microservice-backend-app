# Terraform Backend Configuration para dev - DOKS
# Configurar backend remoto para almacenar el estado de Terraform

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  # Para producción, usar un backend remoto como S3 o GCS:
  # backend "s3" {
  #   bucket         = "ecommerce-terraform-state"
  #   key            = "dev/doks/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
