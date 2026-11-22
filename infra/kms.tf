# ==============================================================================
# S6 — Criptografia em repouso (CMEK - Customer-Managed Encryption Keys)
# Cloud KMS KeyRing e CryptoKeys para criptografia de discos e storage
# ==============================================================================

# Obter dados do projeto atual (número do projeto necessário para service agents)
data "google_project" "current" {
  project_id = var.project_id
}

# Obter a Service Account padrão do Cloud Storage para o projeto
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

# KeyRing central do AutoPrime para chaves gerenciadas pelo cliente
resource "google_kms_key_ring" "autoprime_keyring" {
  name     = "autoprime-keyring"
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.kms_api]
}

# Chave criptográfica para discos do Compute Engine (S6)
resource "google_kms_crypto_key" "autoprime_disk_key" {
  name            = "autoprime-disk-key"
  key_ring        = google_kms_key_ring.autoprime_keyring.id
  rotation_period = "7776000s" # Rotação a cada 90 dias

  labels = {
    env     = "production"
    managed = "terraform"
    purpose = "disk-encryption"
  }
}

# Permissão para o agente do Compute Engine usar a chave de disco
resource "google_kms_crypto_key_iam_binding" "compute_engine_cmek" {
  crypto_key_id = google_kms_crypto_key.autoprime_disk_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
  ]
}

# Chave criptográfica para o Bucket de Backup do GCS (S6)
resource "google_kms_crypto_key" "autoprime_storage_key" {
  name            = "autoprime-storage-key"
  key_ring        = google_kms_key_ring.autoprime_keyring.id
  rotation_period = "7776000s" # Rotação a cada 90 dias

  labels = {
    env     = "production"
    managed = "terraform"
    purpose = "storage-encryption"
  }
}

# Permissão para o agente do Cloud Storage usar a chave de backup
resource "google_kms_crypto_key_iam_binding" "storage_cmek" {
  crypto_key_id = google_kms_crypto_key.autoprime_storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  ]
}
