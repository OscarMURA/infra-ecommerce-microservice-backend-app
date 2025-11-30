# ============================================
# Provider de Google Cloud
# ============================================

# Obtener token de acceso desde gcloud CLI
data "external" "gcloud_token" {
  program = ["bash", "-c", "echo \"{\\\"token\\\": \\\"$(gcloud auth print-access-token)\\\"}\""]
}

provider "google" {
  project      = var.project_id
  region       = var.region
  zone         = var.zone
  access_token = data.external.gcloud_token.result.token
}

# ============================================
# Obtener datos del cluster GKE existente
# ============================================

data "google_container_cluster" "existing" {
  name     = var.cluster_name
  location = var.zone
  project  = var.project_id
}

# ============================================
# Provider de Kubernetes (conecta al cluster existente)
# ============================================

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.existing.endpoint}"
  token                  = data.external.gcloud_token.result.token
  cluster_ca_certificate = base64decode(data.google_container_cluster.existing.master_auth[0].cluster_ca_certificate)
}

# ============================================
# Provider de Helm (para instalar charts)
# ============================================

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.existing.endpoint}"
    token                  = data.external.gcloud_token.result.token
    cluster_ca_certificate = base64decode(data.google_container_cluster.existing.master_auth[0].cluster_ca_certificate)
  }
}
