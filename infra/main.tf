# ==============================================================================
# Configuração do Provedor Google e Habilitação de APIs
# ==============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

# Habilitação das APIs necessárias no GCP

resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  project            = var.project_id
  disable_on_destroy = false
}

resource "google_project_service" "kms_api" {
  service            = "cloudkms.googleapis.com"
  project            = var.project_id
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess_api" {
  service            = "vpcaccess.googleapis.com"
  project            = var.project_id
  disable_on_destroy = false
}

resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  project            = var.project_id
  disable_on_destroy = false
}
