# ==============================================================================
# S6 — Criptografia em repouso + Parte D (Backup Mínimo)
# Bucket GCS para armazenar os dumps do MariaDB com retenção de 2 dias e CMEK
# ==============================================================================

resource "google_storage_bucket" "db_backup" {
  name          = "${var.project_id}-autoprime-db-backup"
  location      = var.region
  force_destroy = true

  # Classe de armazenamento padrão para backups diários
  storage_class = "STANDARD"

  # Versionamento desativado para manter custo zero
  versioning {
    enabled = false
  }

  # Regra de ciclo de vida (B6): apaga automaticamente após 2 dias (retenção máxima permitida)
  lifecycle_rule {
    condition {
      age = var.backup_retention_days # 2 dias
    }
    action {
      type = "Delete"
    }
  }

  # Bloqueia acesso público ao bucket
  public_access_prevention = "enforced"

  # Ativa controle de acesso uniforme no bucket (exigido por políticas do GCP)
  uniform_bucket_level_access = true

  # S6 — Criptografia em repouso explícita com chave CMEK via Cloud KMS
  encryption {
    default_kms_key_name = google_kms_crypto_key.autoprime_storage_key.id
  }

  labels = {
    env     = "production"
    purpose = "db-backup"
    managed = "terraform"
    projeto = "autoprime"
    grupo   = "projeto-integrador"
  }

  depends_on = [
    google_kms_crypto_key_iam_binding.storage_cmek
  ]
}
