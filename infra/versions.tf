# ==============================================================================
# versions.tf — Versão do Terraform e dos Providers (Regra 7.2 do Edital)
# ==============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
