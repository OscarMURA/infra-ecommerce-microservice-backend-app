# Backend Configuration para Desarrollo - AKS
# Descomentar y configurar según tus necesidades

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "terraformstatedev"
#     container_name       = "tfstate"
#     key                  = "dev/aks/terraform.tfstate"
#   }
# }

# Alternativa: Backend local (para desarrollo)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
